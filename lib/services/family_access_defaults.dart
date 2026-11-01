import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// How much a newly invited member may do with one child profile.
enum MemberAccessLevel { none, view, full }

/// Access the owner chooses *before* sending an invitation code or link.
///
/// The invitee does not exist as a member yet, so the choice is kept per
/// family and role until that member appears, then applied once.
class FamilyAccessDefaults {
  FamilyAccessDefaults._();

  static String _accessKey(String familyId, String role) =>
      'bag2school_pending_access_v1_${familyId}_$role';

  static String _knownMembersKey(String familyId) =>
      'bag2school_known_members_v1_$familyId';

  static Future<void> save({
    required String familyId,
    required String role,
    required Map<String, MemberAccessLevel> access,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = access.map(
      (childId, level) => MapEntry(childId, level.name),
    );

    await preferences.setString(
      _accessKey(familyId, role),
      jsonEncode(encoded),
    );
  }

  static Future<Map<String, MemberAccessLevel>> load({
    required String familyId,
    required String role,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_accessKey(familyId, role));

    if (raw == null || raw.isEmpty) {
      return <String, MemberAccessLevel>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, MemberAccessLevel>{};
      }

      return decoded.map((childId, level) {
        final match = MemberAccessLevel.values.firstWhere(
          (value) => value.name == level,
          orElse: () => MemberAccessLevel.none,
        );

        return MapEntry(childId.toString(), match);
      });
    } catch (_) {
      return <String, MemberAccessLevel>{};
    }
  }


  /// Which features (schedule, homework, preparation, exam) the invited member
  /// may use per child. Chosen together with the access level.
  static String _featuresKey(String familyId, String role) =>
      'bag2school_pending_features_v1_${familyId}_$role';

  static Future<void> saveFeatures({
    required String familyId,
    required String role,
    required Map<String, Set<String>> features,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = features.map(
      (childId, list) => MapEntry(childId, list.toList()),
    );

    await preferences.setString(
      _featuresKey(familyId, role),
      jsonEncode(encoded),
    );
  }

  static Future<Map<String, Set<String>>> loadFeatures({
    required String familyId,
    required String role,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_featuresKey(familyId, role));

    if (raw == null || raw.isEmpty) {
      return <String, Set<String>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Set<String>>{};

      return decoded.map((childId, value) {
        final list = value is List
            ? value.map((item) => item.toString()).toSet()
            : <String>{};

        return MapEntry(childId.toString(), list);
      });
    } catch (_) {
      return <String, Set<String>>{};
    }
  }

  /// Members that were already part of this family on this device.
  static Future<Set<String>> loadKnownMembers(String familyId) async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getStringList(_knownMembersKey(familyId))?.toSet() ??
        <String>{};
  }

  static Future<void> saveKnownMembers(
    String familyId,
    Set<String> memberIds,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setStringList(
      _knownMembersKey(familyId),
      memberIds.toList(),
    );
  }
}
