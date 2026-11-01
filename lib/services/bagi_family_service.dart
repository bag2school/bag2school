import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class BagiFamilyService {
  BagiFamilyService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>?> loadCurrentFamily({
    String? familyId,
  }) async {
    final user = _client.auth.currentUser;

    debugPrint('[Family] Current auth user: ${user?.id}');

    if (user == null) {
      return null;
    }

    var memberQuery = _client
        .from('family_members')
        .select('id, family_id, profile_id, role, display_name')
        .eq('profile_id', user.id);

    if (familyId != null && familyId.isNotEmpty) {
      memberQuery = memberQuery.eq('family_id', familyId);
    }

    final member = await memberQuery.maybeSingle();

    debugPrint('[Family] Member result: $member');

    if (member == null) {
      return null;
    }

    final family = await _client
        .from('families')
        .select('id, name, created_by')
        .eq('id', member['family_id'])
        .maybeSingle();

    if (family == null) {
      return null;
    }

    return <String, dynamic>{
      'family': Map<String, dynamic>.from(family),
      'member': Map<String, dynamic>.from(member),
    };
  }

  static Future<List<Map<String, dynamic>>> loadFamilyMembers(
    String familyId,
  ) async {
    final rows = await _client
        .from('family_members')
        .select('id, family_id, profile_id, role, display_name')
        .eq('family_id', familyId)
        .order('created_at');

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<List<Map<String, dynamic>>> loadUserFamilies() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return <Map<String, dynamic>>[];
    }

    final memberships = await _client
        .from('family_members')
        .select('family_id, role, display_name')
        .eq('profile_id', user.id)
        .order('created_at');

    if (memberships.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final familyIds = memberships
        .map((row) => row['family_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (familyIds.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final families = await _client
        .from('families')
        .select('id, name, created_by')
        .inFilter('id', familyIds);

    final familyById = <String, Map<String, dynamic>>{
      for (final row in families)
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    return memberships
        .map((membership) {
          final familyId = membership['family_id']?.toString() ?? '';
          final family = familyById[familyId];

          if (family == null) {
            return null;
          }

          return <String, dynamic>{
            'id': familyId,
            'name': family['name']?.toString() ?? 'Family',
            'role': membership['role']?.toString() ?? '',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadChildren(
    String familyId,
  ) async {
    final rows = await _client
        .from('children')
        .select('id, family_id, name, grade, avatar_url, birth_date, gender')
        .eq('family_id', familyId)
        .order('created_at');

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<String?> createFamily({
    required String familyName,
    required String displayName,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      debugPrint('[Family] Create family: no authenticated user');
      return null;
    }

    try {
      final result = await _client.rpc(
        'create_family',
        params: {
          'p_family_name': familyName.trim(),
          'p_display_name': displayName.trim(),
        },
      );

      debugPrint('[Family] Create family RPC result: $result');

      if (result is Map) {
        return result['id']?.toString();
      }

      return null;
    } catch (error) {
      debugPrint('[Family] Create family RPC error: $error');
      return null;
    }
  }

  // ============================================================
  // FIND PROFILE BY EMAIL
  // ============================================================

  static Future<Map<String, dynamic>?> findProfileByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return null;
    }

    try {
      final result = await _client.rpc(
        'find_profile_by_email',
        params: {'p_email': normalizedEmail},
      );

      if (result == null) {
        return null;
      }

      if (result is List && result.isEmpty) {
        return null;
      }

      if (result is List) {
        return Map<String, dynamic>.from(result.first);
      }

      return Map<String, dynamic>.from(result);
    } catch (error) {
      debugPrint('[Family Invitation] Find profile error: $error');
      return null;
    }
  }

  // ============================================================
  // CREATE FAMILY JOIN REQUEST
  // ============================================================

  static Future<Map<String, dynamic>> createFamilyJoinRequest({
    required String familyId,
    required String invitationCodeId,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return {'success': false, 'reason': 'not_authenticated'};
    }

    try {
      final existingMember = await _client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('profile_id', user.id)
          .maybeSingle();

      if (existingMember != null) {
        return {'success': false, 'reason': 'already_member'};
      }

      final existingRequest = await _client
          .from('family_join_requests')
          .select('id')
          .eq('family_id', familyId)
          .eq('profile_id', user.id)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        return {'success': false, 'reason': 'already_pending'};
      }

      await _client.from('family_join_requests').insert({
        'family_id': familyId,
        'profile_id': user.id,
        'invitation_code_id': invitationCodeId,
        'status': 'pending',
      });

      return {'success': true, 'reason': 'created'};
    } catch (error) {
      debugPrint('[Family Join Request] Create error: $error');

      return {'success': false, 'reason': 'error'};
    }
  }

  // ============================================================
  // CREATE FAMILY INVITATION
  // ============================================================

  static Future<bool> createFamilyInvitation({
    required String familyId,
    required String invitedProfileId,
    required String invitedEmail,
    required String role,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      debugPrint('[Family Invitation] No authenticated user');
      return false;
    }

    try {
      await _client.from('family_invitations').insert({
        'family_id': familyId,
        'invited_profile_id': invitedProfileId,
        'invited_email': invitedEmail.trim().toLowerCase(),
        'invited_by_profile_id': user.id,
        'role': role,
      });

      return true;
    } catch (error) {
      debugPrint('[Family Invitation] Create error: $error');
      return false;
    }
  }

  // ============================================================
  // GENERATE FAMILY INVITATION CODE
  // ============================================================

  // ============================================================
  // GENERATE / GET ACTIVE FAMILY INVITATION CODE
  // ============================================================

  static Future<Map<String, dynamic>?> createFamilyInvitationCode({
    required String familyId,
    required String role,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      debugPrint('[Family Invitation Code] No authenticated user');
      return null;
    }

    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    String generateCode() {
      final random = DateTime.now().microsecondsSinceEpoch;

      final buffer = StringBuffer();

      for (var i = 0; i < 4; i++) {
        final index = (random ~/ (i + 1) + i * 17) % characters.length;

        buffer.write(characters[index]);
      }

      return buffer.toString();
    }

    try {
      String databaseRole;

      switch (role) {
        case 'parentGuardian':
        case 'parent':
          databaseRole = 'parent_guardian';
          break;

        case 'caregiver':
          databaseRole = 'caregiver';
          break;

        case 'child':
          databaseRole = 'child';
          break;

        case 'owner':
          databaseRole = 'owner';
          break;

        default:
          databaseRole = role;
      }

      // Every time the owner opens the invite screen we hand out a fresh
      // code and retire the old one. Codes already expire after ten minutes,
      // and reusing a previous code was the source of repeated "why is it the
      // same code" confusion.
      debugPrint('[Family Invitation Code] Rotating to a new code.');

      // ==========================================================
      // CREATE NEW CODE
      // ==========================================================

      // Clean up any remaining active codes.
      await _client
          .from('family_invitation_codes')
          .update({'is_active': false})
          .eq('family_id', familyId)
          .eq('is_active', true);

      final code = generateCode();

      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));

      final result = await _client
          .from('family_invitation_codes')
          .insert({
            'family_id': familyId,
            'code': code,
            'created_by_profile_id': user.id,
            'role': databaseRole,
            'expires_at': expiresAt.toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();

      debugPrint('[Family Invitation Code] Created: ${result['code']}');

      return Map<String, dynamic>.from(result);
    } catch (error) {
      debugPrint('[Family Invitation Code] Create error: $error');
      return null;
    }
  }

  // ============================================================
  // VALIDATE FAMILY INVITATION CODE
  // ============================================================
  // ============================================================
  // CREATE FAMILY INVITATION LINK
  // ============================================================

  static Future<Map<String, dynamic>?> createFamilyInvitationLink({
    required String familyId,
    required String role,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      debugPrint('[Family Invitation Link] No authenticated user');
      return null;
    }

    String databaseRole;

    switch (role) {
      case 'parentGuardian':
      case 'parent':
        databaseRole = 'parent_guardian';
        break;
      case 'caregiver':
        databaseRole = 'caregiver';
        break;
      default:
        debugPrint('[Family Invitation Link] Invalid role: $role');
        return null;
    }

    try {
      final result = await _client.rpc(
        'create_family_invitation_link',
        params: {'p_family_id': familyId, 'p_role': databaseRole},
      );

      debugPrint('[Family Invitation Link] Created: $result');

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return null;
    } catch (error) {
      debugPrint('[Family Invitation Link] Create error: $error');
      return null;
    }
  }
  // ============================================================
  // VALIDATE FAMILY INVITATION CODE
  // ============================================================

  static Future<Map<String, dynamic>> validateFamilyInvitationCode({
    required String code,
  }) async {
    try {
      final normalizedCode = code.trim().toUpperCase();

      debugPrint(
        '[Family Invitation Code] Calling validation RPC for: $normalizedCode',
      );

      final result = await _client.rpc(
        'validate_family_invitation_code',
        params: {'p_code': normalizedCode},
      );

      debugPrint('[Family Invitation Code] RPC result: $result');

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return {'valid': false, 'reason': 'error'};
    } catch (error) {
      debugPrint('[Family Invitation Code] Validation error: $error');

      return {'valid': false, 'reason': 'error'};
    }
  }

  // ============================================================
  // JOIN FAMILY WITH INVITATION CODE
  // ============================================================

  static Future<Map<String, dynamic>> joinFamilyWithInvitationCode({
    required String code,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return {'success': false, 'reason': 'not_authenticated'};
    }

    try {
      debugPrint(
        '[Family Invitation Code] Joining via RPC: ${code.trim().toUpperCase()}',
      );

      final result = await _client.rpc(
        'join_family_with_invitation_code',
        params: {'p_code': code.trim().toUpperCase()},
      );

      debugPrint('[Family Invitation Code] Join RPC result: $result');

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return {'success': false, 'reason': 'error'};
    } catch (error) {
      debugPrint('[Family Invitation Code] Join RPC error: $error');

      return {'success': false, 'reason': 'error'};
    }
  }

  // ============================================================
  // CONSUME FAMILY INVITATION LINK
  // ============================================================

  static Future<Map<String, dynamic>> consumeFamilyInvitationLink({
    required String token,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return {'success': false, 'reason': 'not_authenticated'};
    }

    try {
      debugPrint('[Family Invitation Link] Consuming invitation link');

      final result = await _client.rpc(
        'consume_family_invitation_link',
        params: {'p_token': token.trim()},
      );

      debugPrint('[Family Invitation Link] Consume RPC result: $result');

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      return {'success': false, 'reason': 'error'};
    } catch (error) {
      debugPrint('[Family Invitation Link] Consume RPC error: $error');

      return {'success': false, 'reason': 'error'};
    }
  }

  // ============================================================
  // GET PENDING FAMILY JOIN REQUEST
  // ============================================================

  static Future<Map<String, dynamic>?> getPendingFamilyJoinRequest() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final request = await _client
          .from('family_join_requests')
          .select('id, family_id, invitation_code_id, status, created_at')
          .eq('profile_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (request == null) {
        return null;
      }

      return Map<String, dynamic>.from(request);
    } catch (error) {
      debugPrint('[Family Join Request] Pending request check error: $error');

      return null;
    }
  }

  static Future<bool> renameFamily({
    required String familyId,
    required String name,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return false;

    try {
      final updatedFamily = await _client
          .from('families')
          .update({'name': normalizedName})
          .eq('id', familyId)
          .select('id')
          .maybeSingle();
      return updatedFamily != null;
    } catch (error) {
      debugPrint('[Family] Rename error: $error');
      return false;
    }
  }

  static Future<Map<String, dynamic>> leaveFamily({
    required String familyId,
    String? newOwnerProfileId,
  }) async {
    try {
      final result = await _client.rpc(
        'leave_family_with_transfer',
        params: {
          'p_family_id': familyId,
          'p_new_owner_profile_id': newOwnerProfileId,
        },
      );
      if (result is Map) return Map<String, dynamic>.from(result);
      return {'success': result == true};
    } catch (error) {
      debugPrint('[Family] Leave error: $error');
      return {'success': false, 'reason': error.toString()};
    }
  }

  static Future<bool> deleteOwnAccount() async {
    try {
      final result = await _client.rpc('delete_own_account');
      return result == true || (result is Map && result['success'] == true);
    } catch (error) {
      debugPrint('[Account] Delete error: $error');
      return false;
    }
  }
}
