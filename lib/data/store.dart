import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_models.dart';
import '../models/child_profile.dart';
import '../models/family_models.dart';
import '../services/bagi_family_service.dart';
import '../services/bagi_local_auth_service.dart';
import '../services/family_access_defaults.dart';
import '../widgets/app_notification.dart';
import 'serializers.dart';

// Extracted from lib/main.dart (step 3 of the split in
// docs/knowledge-graph.md): the family store, its per-child bundle cache
// and the client side authorization helper.

class LocalAuthorization {
  static FamilyMember? _currentMember() =>
      Bag2SchoolStore.familyMemberForCurrentAccount();

  static FamilyAccessGrant? _grantFor(String childId) {
    final member = _currentMember();
    if (member == null) return null;
    return Bag2SchoolStore.accessGrantFor(childId, member.id);
  }

  static bool _isOwner() => _currentMember()?.role == FamilyMemberRole.owner;

  static bool canView(LocalPermissionFeature feature, {String? childId}) {
    if (!Bag2SchoolStore.isSignedIn) return false;
    if (_isOwner()) return true;

    final id = childId ?? Bag2SchoolStore.activeChildId;
    final grant = _grantFor(id);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.viewSchedule;
      case LocalPermissionFeature.homework:
        return grant.viewHomework;
      case LocalPermissionFeature.preparation:
        return grant.viewPreparation;
      case LocalPermissionFeature.exam:
        return grant.viewExam;
    }
  }

  static bool canEdit(LocalPermissionFeature feature, {String? childId}) {
    if (!Bag2SchoolStore.isSignedIn) return false;
    if (_isOwner()) return true;

    final id = childId ?? Bag2SchoolStore.activeChildId;
    final grant = _grantFor(id);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.editSchedule;
      case LocalPermissionFeature.homework:
        return grant.editHomework;
      case LocalPermissionFeature.preparation:
        return grant.editPreparation;
      case LocalPermissionFeature.exam:
        return grant.editExam;
    }
  }

  static bool canEditActive(LocalPermissionFeature feature) =>
      canEdit(feature, childId: Bag2SchoolStore.activeChildId);

  static void requestViewAccess(
    BuildContext context, {
    required LocalPermissionFeature feature,
    bool requestEdit = false,
  }) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    if (member == null) return;
    final childId = Bag2SchoolStore.activeChildId;

    final exists = Bag2SchoolStore.accessRequests.any(
      (request) =>
          request.requesterMemberId == member.id &&
          request.childId == childId &&
          request.feature == feature &&
          request.requestEdit == requestEdit &&
          request.status == AccessRequestStatus.pending,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your access request is already waiting for the Family Owner.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Bag2SchoolStore.accessRequests.add(
      LocalAccessRequest(
        id: 'request-${DateTime.now().microsecondsSinceEpoch}',
        requesterMemberId: member.id,
        childId: childId,
        feature: feature,
        requestEdit: requestEdit,
        createdAt: DateTime.now(),
      ),
    );

    showAppNotification(
      context,
      title: requestEdit ? 'Edit access requested' : 'Access request sent',
      message: requestEdit
          ? 'Your edit access request has been sent to the Family Owner.'
          : 'Your access request has been sent to the Family Owner.',
      icon: Icons.mail_outline_rounded,
    );
  }

  static String featureLabel(LocalPermissionFeature feature) {
    switch (feature) {
      case LocalPermissionFeature.schedule:
        return 'Schedule';
      case LocalPermissionFeature.homework:
        return 'Homework';
      case LocalPermissionFeature.preparation:
        return 'Preparation';
      case LocalPermissionFeature.exam:
        return 'Exam';
    }
  }

  static Future<void> showDenied(
    BuildContext context,
    String action, {
    String? featureLabel,
    LocalPermissionFeature? feature,
    bool requestEdit = false,
  }) async {
    if (feature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You don’t have permission to $action ${featureLabel ?? 'this item'} yet. '
            'Please ask the Family Owner to grant you access.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final wantsEdit =
        requestEdit ||
        action == 'add' ||
        action == 'edit' ||
        action == 'delete' ||
        action == 'change';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Access needed',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF302722),
          ),
        ),
        content: Text(
          wantsEdit
              ? 'You don’t have permission to $action ${featureLabel ?? 'this item'}. '
                    'Would you like to request edit access from the Family Owner?'
              : 'You don’t have permission to view ${featureLabel ?? 'this item'}. '
                    'Would you like to request access from the Family Owner?',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF756B65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              requestViewAccess(
                context,
                feature: feature,
                requestEdit: wantsEdit,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A21),
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Access'),
          ),
        ],
      ),
    );
  }

  static Widget restrictedView({
    required String title,
    required String feature,
    required BuildContext context,
    required LocalPermissionFeature permission,
  }) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    final alreadyPending =
        member != null &&
        Bag2SchoolStore.accessRequests.any(
          (request) =>
              request.requesterMemberId == member.id &&
              request.childId == Bag2SchoolStore.activeChildId &&
              request.feature == permission &&
              request.status == AccessRequestStatus.pending,
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 54,
              color: Color(0xFF9B8F87),
            ),
            const SizedBox(height: 14),
            Text(
              '$title access is limited',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF302722),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'You don’t currently have permission to view $feature for this child.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: alreadyPending
                  ? null
                  : () => requestViewAccess(context, feature: permission),
              icon: Icon(
                alreadyPending
                    ? Icons.hourglass_top_rounded
                    : Icons.lock_open_rounded,
              ),
              label: Text(
                alreadyPending ? 'Request pending' : 'Request Access',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE6DED8),
                disabledForegroundColor: const Color(0xFF8A7E76),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The Family Owner can approve or decline this request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Color(0xFF8A7E76)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget authorizedView({
    required BuildContext context,
    required LocalPermissionFeature feature,
    required String title,
    required String featureLabel,
    required Widget child,
    String? childId,
  }) {
    return canView(feature, childId: childId ?? Bag2SchoolStore.activeChildId)
        ? child
        : restrictedView(
            context: context,
            permission: feature,
            title: title,
            feature: featureLabel,
          );
  }
}

/// Everything saved for one child, as read from local storage.
class _ChildDataBundle {
  final List<BagActivity> activities;
  final List<PreparationItem> preparations;
  final List<HomeworkItem> homeworks;
  final Map<String, bool> homeworkPreparationCompletion;
  final Set<String> cancelledActivityOccurrences;
  final Map<String, Set<String>> cancelledActivityDatesBySeries;
  final Map<String, bool> preparationOccurrenceCompletion;
  final Set<String> preparationOccurrenceHidden;
  final Map<String, List<PreparationItem>> preparationOccurrenceOverrides;

  const _ChildDataBundle({
    required this.activities,
    required this.preparations,
    required this.homeworks,
    required this.homeworkPreparationCompletion,
    required this.cancelledActivityOccurrences,
    required this.cancelledActivityDatesBySeries,
    required this.preparationOccurrenceCompletion,
    required this.preparationOccurrenceHidden,
    required this.preparationOccurrenceOverrides,
  });

  Map<String, dynamic> toJson() => {
    'activities': activities.map(activityToJson).toList(),
    'preparations': preparations.map(preparationToJson).toList(),
    'homeworks': homeworks.map(homeworkToJson).toList(),
    'homeworkPreparationCompletion': homeworkPreparationCompletion,
    'cancelledActivityOccurrences': cancelledActivityOccurrences.toList(),
    'cancelledActivityDatesBySeries': cancelledActivityDatesBySeries.map(
      (key, value) => MapEntry(key, value.toList()),
    ),
    'preparationOccurrenceCompletion': preparationOccurrenceCompletion,
    'preparationOccurrenceHidden': preparationOccurrenceHidden.toList(),
    'preparationOccurrenceOverrides': preparationOccurrenceOverrides.map(
      (key, value) => MapEntry(key, value.map(preparationToJson).toList()),
    ),
  };

  factory _ChildDataBundle.fromJson(Map<String, dynamic> json) {
    Map<String, bool> boolMap(Object? value) => value is Map
        ? value.map((key, item) => MapEntry(key.toString(), item == true))
        : <String, bool>{};

    List<dynamic> list(Object? value) => value is List ? value : <dynamic>[];

    return _ChildDataBundle(
      activities: list(json['activities'])
          .whereType<Map>()
          .map((item) => activityFromJson(Map<String, dynamic>.from(item)))
          .toList(),
      preparations: list(json['preparations'])
          .whereType<Map>()
          .map((item) => preparationFromJson(Map<String, dynamic>.from(item)))
          .toList(),
      homeworks: list(json['homeworks'])
          .whereType<Map>()
          .map((item) => homeworkFromJson(Map<String, dynamic>.from(item)))
          .toList(),
      homeworkPreparationCompletion: boolMap(
        json['homeworkPreparationCompletion'],
      ),
      cancelledActivityOccurrences: list(json['cancelledActivityOccurrences'])
          .map((value) => value.toString())
          .toSet(),
      cancelledActivityDatesBySeries:
          (json['cancelledActivityDatesBySeries'] as Map? ?? {}).map(
            (key, value) => MapEntry(
              key.toString(),
              list(value).map((date) => date.toString()).toSet(),
            ),
          ),
      preparationOccurrenceCompletion: boolMap(
        json['preparationOccurrenceCompletion'],
      ),
      preparationOccurrenceHidden: list(json['preparationOccurrenceHidden'])
          .map((value) => value.toString())
          .toSet(),
      preparationOccurrenceOverrides:
          (json['preparationOccurrenceOverrides'] as Map? ?? {}).map(
            (key, value) => MapEntry(
              key.toString(),
              list(value)
                  .whereType<Map>()
                  .map(
                    (item) =>
                        preparationFromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList(),
            ),
          ),
    );
  }
}

class Bag2SchoolStore {
  // Multi-child local profile foundation. Data ownership by child will be
  // connected to Account/Cloud later; for now the selected child drives the UI.
  static final List<ChildProfile> childProfiles = <ChildProfile>[];

  static String activeChildId = '';

  static String? currentFamilyId;
  static String? currentFamilyName;
  static String? pendingInvitationToken;

  static List<Map<String, dynamic>> familyOptions = <Map<String, dynamic>>[];

  static Future<bool> loadSupabaseFamily() async {
    try {
      final options = await BagiFamilyService.loadUserFamilies();

      familyOptions = options;

      debugPrint('[Family Switch] OPTIONS: $options');

      if (options.isEmpty) {
        currentFamilyId = null;
        currentFamilyName = null;

        childProfiles.clear();
        activeChildId = '';
        _clearActiveChildData();

        return false;
      }

      Map<String, dynamic> activeFamily;

      if (currentFamilyId != null &&
          options.any((family) => family['id'] == currentFamilyId)) {
        activeFamily = options.firstWhere(
          (family) => family['id'] == currentFamilyId,
        );
      } else {
        activeFamily = options.first;
      }

      currentFamilyId = activeFamily['id']?.toString();
      currentFamilyName = activeFamily['name']?.toString();

      final familyId = currentFamilyId;

      if (familyId == null || familyId.isEmpty) {
        return false;
      }

      final familyMemberRows = await BagiFamilyService.loadFamilyMembers(
        familyId,
      );

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      final currentMember = familyMemberRows.firstWhere(
        (row) => row['profile_id']?.toString() == currentUserId,
        orElse: () => <String, dynamic>{},
      );

      final member = currentMember;

      FamilyMemberRole role;

      switch (member['role']?.toString()) {
        case 'owner':
          role = FamilyMemberRole.owner;
          break;

        case 'parent_guardian':
        case 'parentGuardian':
        case 'parent':
          role = FamilyMemberRole.parentGuardian;
          break;

        case 'caregiver':
          role = FamilyMemberRole.caregiver;
          break;

        case 'child':
          role = FamilyMemberRole.child;
          break;

        default:
          role = FamilyMemberRole.parentGuardian;
      }

      familyMembers
        ..clear()
        ..addAll(
          familyMemberRows.map((row) {
            FamilyMemberRole memberRole;

            switch (row['role']?.toString()) {
              case 'owner':
                memberRole = FamilyMemberRole.owner;
                break;

              case 'parent_guardian':
              case 'parentGuardian':
              case 'parent':
                memberRole = FamilyMemberRole.parentGuardian;
                break;

              case 'caregiver':
                memberRole = FamilyMemberRole.caregiver;
                break;

              case 'child':
                memberRole = FamilyMemberRole.child;
                break;

              default:
                memberRole = FamilyMemberRole.parentGuardian;
            }

            final profileId = row['profile_id']?.toString();

            return FamilyMember(
              id: row['id']?.toString() ?? '',
              displayName: row['display_name']?.toString() ?? 'Family Member',
              role: memberRole,
              accountId: profileId,
            );
          }),
        );

      debugPrint('========================================');
      debugPrint('[Family] SUPABASE MEMBER ID: ${member['id']}');
      debugPrint('[Family] SUPABASE PROFILE ID: ${member['profile_id']}');
      debugPrint('[Family] SUPABASE ROLE: ${member['role']}');
      debugPrint('[Family] CURRENT USER ID: $currentUserId');
      debugPrint('========================================');

      final rows = await BagiFamilyService.loadChildren(familyId);

      final loadedChildren = rows
          .map(
            (row) => ChildProfile(
              id: row['id']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              grade: row['grade']?.toString() ?? '',
              avatarUrl: row['avatar_url']?.toString(),
              gender: row['gender']?.toString(),
            ),
          )
          .where((child) => child.id.isNotEmpty && child.name.isNotEmpty)
          .toList();

      childProfiles
        ..clear()
        ..addAll(loadedChildren);

      if (childProfiles.isEmpty) {
        activeChildId = '';
      } else if (!childProfiles.any((child) => child.id == activeChildId)) {
        activeChildId = childProfiles.first.id;
      }

      if (activeChildId.isNotEmpty) {
        await restoreActiveChildSchoolData();
      }

      // Apply the access the owner picked when inviting to members that just
      // joined. Safe to run on every load; existing members are left alone.
      try {
        await restoreAccessGrants();
        await applyPendingAccessToNewMembers();
      } catch (error) {
        debugPrint('[Access] Skipped restoring grants: $error');
      }

      // Family exists, even if there are no children yet.
      isOfflineData = false;
      await cacheFamilySnapshot();
      return true;
    } catch (e) {
      debugPrint('[Family] loadSupabaseFamily ERROR: $e');

      // A lost connection must not look like a lost family.
      if (await restoreFamilySnapshot()) {
        debugPrint('[Family] Using the cached family (offline)');
        return true;
      }

      currentFamilyId = null;
      currentFamilyName = null;

      childProfiles.clear();
      activeChildId = '';
      _clearActiveChildData();

      return false;
    }
  }

  // V13 local account/session bridge.
  // The selected local test account is backed by a real
  // Supabase Auth user so account-specific Bagi identity
  // can be loaded from the correct profile.
  static final List<LocalAccount> localAccounts = <LocalAccount>[
    const LocalAccount(
      id: 'account-owner',
      displayName: 'Family Owner',
      email: 'owner@bag2school.local',
      familyMemberId: 'member-owner',
      authEmail: 'owner@bag2school.local',
    ),
    const LocalAccount(
      id: 'account-parent',
      displayName: 'Parent Test',
      email: 'parent@bag2school.local',
      familyMemberId: 'member-parent',
      authEmail: 'parent@bag2school.local',
    ),
    const LocalAccount(
      id: 'account-caregiver',
      displayName: 'Caregiver Test',
      email: 'caregiver@bag2school.local',
      familyMemberId: 'member-caregiver',
      authEmail: 'caregiver@bag2school.local',
    ),
  ];

  static String? currentAccountId;

  static LocalAccount? get currentAccount {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final email = user.email?.trim() ?? '';

    final displayName = user.userMetadata?['display_name']?.toString().trim();

    final member = familyMembers.cast<FamilyMember?>().firstWhere(
      (entry) => entry?.accountId == user.id,
      orElse: () => null,
    );

    return LocalAccount(
      id: 'supabase-${user.id}',
      displayName: displayName == null || displayName.isEmpty
          ? (email.isEmpty ? 'Bag2School Family' : email.split('@').first)
          : displayName,
      email: email,
      familyMemberId: member?.id ?? '',
      authEmail: email,
    );
  }

  static bool get isSignedIn =>
      Supabase.instance.client.auth.currentUser != null;

  static Future<bool> restoreSupabaseSession() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      currentAccountId = null;
      return false;
    }

    currentAccountId = 'supabase-${user.id}';

    return true;
  }

  static Future<bool> signInLocal(String accountId) async {
    LocalAccount? account;

    for (final entry in localAccounts) {
      if (entry.id == accountId) {
        account = entry;
        break;
      }
    }

    if (account == null) {
      return false;
    }

    final success = await BagiLocalAuthService.signIn(email: account.authEmail);

    if (!success) {
      return false;
    }

    currentAccountId = account.id;

    return true;
  }

  static Future<void> signOutLocal() async {
    currentAccountId = null;
    await BagiLocalAuthService.signOut();
  }

  static void updateCurrentAccount({String? displayName, String? email}) {
    final index = localAccounts.indexWhere(
      (account) => account.id == currentAccountId,
    );
    if (index < 0) return;
    localAccounts[index] = localAccounts[index].copyWith(
      displayName: displayName,
      email: email,
    );
  }

  static FamilyMember? familyMemberForCurrentAccount() {
    final account = currentAccount;
    if (account == null) return null;
    for (final member in familyMembers) {
      if (member.id == account.familyMemberId) return member;
    }
    return null;
  }

  static String createLocalAccountForFamilyMember({
    required String memberId,
    required String displayName,
  }) {
    final id = 'account-${DateTime.now().microsecondsSinceEpoch}';

    final member = familyMembers.cast<FamilyMember?>().firstWhere(
      (entry) => entry?.id == memberId,
      orElse: () => null,
    );

    String authEmail;

    switch (member?.role) {
      case FamilyMemberRole.owner:
        authEmail = 'owner@bag2school.local';
        break;

      case FamilyMemberRole.parentGuardian:
        authEmail = 'parent@bag2school.local';
        break;

      case FamilyMemberRole.caregiver:
        authEmail = 'caregiver@bag2school.local';
        break;

      case FamilyMemberRole.child:
        // Child accounts are not enabled for Supabase test
        // authentication yet.
        authEmail = '';
        break;

      case null:
        authEmail = '';
        break;
    }

    final email =
        '${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@bag2school.local';

    localAccounts.add(
      LocalAccount(
        id: id,
        displayName: displayName,
        email: email,
        familyMemberId: memberId,
        authEmail: authEmail,
      ),
    );

    return id;
  }

  static bool canViewChild(String childId, {String? memberId}) {
    final member = memberId == null
        ? familyMemberForCurrentAccount()
        : familyMembers.cast<FamilyMember?>().firstWhere(
            (entry) => entry?.id == memberId,
            orElse: () => null,
          );
    if (member == null) return false;

    if (member.role == FamilyMemberRole.owner) {
      return true;
    }

    if (member.role == FamilyMemberRole.child) {
      final child = childProfiles.cast<ChildProfile?>().firstWhere(
        (entry) => entry?.id == childId,
        orElse: () => null,
      );
      return child?.id == childId;
    }

    return familyAccessGrants.containsKey(
      familyAccessGrantKey(childId, member.id),
    );
  }

  static FamilyAccessGrant? currentGrantForChild(String childId) {
    final member = familyMemberForCurrentAccount();
    if (member == null) return null;
    return accessGrantFor(childId, member.id);
  }

  // V12 Family & Access foundation. These remain local placeholders until
  // Account/Cloud Sync is implemented.
  // V12 Family & Access foundation. These remain local placeholders until
  // Account/Cloud Sync is implemented.
  static final List<FamilyMember> familyMembers = <FamilyMember>[
    const FamilyMember(
      id: 'member-owner',
      displayName: 'Family Owner',
      role: FamilyMemberRole.owner,
      accountId: 'account-owner',
    ),
    const FamilyMember(
      id: 'member-parent',
      displayName: 'Parent Test',
      role: FamilyMemberRole.parentGuardian,
      accountId: 'account-parent',
    ),
    const FamilyMember(
      id: 'member-caregiver',
      displayName: 'Caregiver Test',
      role: FamilyMemberRole.caregiver,
      accountId: 'account-caregiver',
    ),
  ];

  static final Map<String, ChildAccessSettings> childAccessByChildId =
      <String, ChildAccessSettings>{
        'child-1': const ChildAccessSettings(childId: 'child-1'),
      };

  // Key: childId|memberId. Local grant simulation until Account/Cloud.
  static final Map<String, FamilyAccessGrant> familyAccessGrants =
      <String, FamilyAccessGrant>{};

  static final List<LocalAccessRequest> accessRequests = <LocalAccessRequest>[];

  static final List<LocalFamilyNotification> familyNotifications =
      <LocalFamilyNotification>[];

  static final List<LocalFamilyActivity> familyActivities =
      <LocalFamilyActivity>[];

  static final Set<String> readAccessRequestIds = <String>{};
  static final Set<String> readAccessResponseIds = <String>{};
  static final Set<String> readNotificationIds = <String>{};

  static const String _familyActivityStorageKey =
      'bag2school_family_activity_v1';
  static const String _familyNotificationStorageKey =
      'bag2school_family_notifications_v1';

  static Future<void> restoreLocalFamilyActivity() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_familyActivityStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final rows = jsonDecode(raw) as List<dynamic>;
        familyActivities
          ..clear()
          ..addAll(
            rows.whereType<Map>().map((row) {
              final featureName = row['feature']?.toString();
              final feature = LocalPermissionFeature.values.firstWhere(
                (value) => value.name == featureName,
                orElse: () => LocalPermissionFeature.schedule,
              );
              return LocalFamilyActivity(
                id: row['id']?.toString() ?? '',
                familyId: row['familyId']?.toString(),
                actorMemberId: row['actorMemberId']?.toString() ?? '',
                actorName: row['actorName']?.toString() ?? '',
                childId: row['childId']?.toString() ?? '',
                feature: feature,
                category: row['category']?.toString() ?? '',
                action: row['action']?.toString() ?? '',
                title: row['title']?.toString() ?? '',
                message: row['message']?.toString() ?? '',
                createdAt:
                    DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                entityId: row['entityId']?.toString(),
              );
            }),
          );
      }
      final notificationRaw = preferences.getString(
        _familyNotificationStorageKey,
      );
      if (notificationRaw != null && notificationRaw.isNotEmpty) {
        final notificationRows =
            jsonDecode(notificationRaw) as Map<String, dynamic>;
        familyNotifications
          ..clear()
          ..addAll(
            (notificationRows['items'] as List<dynamic>).whereType<Map>().map(
              (row) => LocalFamilyNotification(
                id: row['id']?.toString() ?? '',
                recipientMemberId: row['recipientMemberId']?.toString() ?? '',
                childId: row['childId']?.toString() ?? '',
                title: row['title']?.toString() ?? '',
                message: row['message']?.toString() ?? '',
                createdAt:
                    DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                entityType: row['entityType']?.toString() ?? '',
                entityId: row['entityId']?.toString(),
              ),
            ),
          );
        readNotificationIds
          ..clear()
          ..addAll(
            (notificationRows['readIds'] as List<dynamic>? ?? []).map(
              (id) => id.toString(),
            ),
          );
      }
    } catch (error) {
      debugPrint('[Family Activity] Local restore error: $error');
    }
  }

  static Future<void> _persistLocalFamilyActivity() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _familyActivityStorageKey,
        jsonEncode(
          familyActivities
              .map(
                (activity) => {
                  'id': activity.id,
                  'familyId': activity.familyId,
                  'actorMemberId': activity.actorMemberId,
                  'actorName': activity.actorName,
                  'childId': activity.childId,
                  'feature': activity.feature.name,
                  'category': activity.category,
                  'action': activity.action,
                  'title': activity.title,
                  'message': activity.message,
                  'createdAt': activity.createdAt.toIso8601String(),
                  'entityId': activity.entityId,
                },
              )
              .toList(),
        ),
      );
    } catch (error) {
      debugPrint('[Family Activity] Local save error: $error');
    }
  }

  static Future<void> _persistLocalFamilyNotifications() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _familyNotificationStorageKey,
        jsonEncode({
          'items': familyNotifications
              .map(
                (notification) => {
                  'id': notification.id,
                  'recipientMemberId': notification.recipientMemberId,
                  'childId': notification.childId,
                  'title': notification.title,
                  'message': notification.message,
                  'createdAt': notification.createdAt.toIso8601String(),
                  'entityType': notification.entityType,
                  'entityId': notification.entityId,
                },
              )
              .toList(),
          'readIds': readNotificationIds.toList(),
        }),
      );
    } catch (error) {
      debugPrint('[Family Activity] Notification save error: $error');
    }
  }

  // The notification inbox is bounded; Family Activity remains the complete
  // history/audit trail.
  static const int maxStoredReadNotificationsPerMember = 50;

  static void pruneNotificationInbox() {
    final memberIds = familyMembers.map((member) => member.id).toSet();

    for (final memberId in memberIds) {
      final items =
          familyNotifications
              .where(
                (notification) => notification.recipientMemberId == memberId,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final unread = items.where(
        (notification) => !readNotificationIds.contains(notification.id),
      );
      final read = items.where(
        (notification) => readNotificationIds.contains(notification.id),
      );

      final keepIds = <String>{
        ...unread.map((notification) => notification.id),
        ...read
            .take(maxStoredReadNotificationsPerMember)
            .map((notification) => notification.id),
      };

      familyNotifications.removeWhere(
        (notification) =>
            notification.recipientMemberId == memberId &&
            !keepIds.contains(notification.id),
      );
    }

    readNotificationIds.removeWhere(
      (id) => !familyNotifications.any((notification) => notification.id == id),
    );
  }

  static int get pendingAccessRequestCount {
    final member = familyMemberForCurrentAccount();
    if (member?.role != FamilyMemberRole.owner) return 0;
    return accessRequests
        .where(
          (request) =>
              request.status == AccessRequestStatus.pending &&
              !readAccessRequestIds.contains(request.id),
        )
        .length;
  }

  static int get currentMemberNotificationCount {
    final unreadActivity = notificationsForCurrentMember()
        .where((notification) => !readNotificationIds.contains(notification.id))
        .length;
    final unreadAccessResponses = responseNotificationsForCurrentMember()
        .where((request) => !readAccessResponseIds.contains(request.id))
        .length;
    return unreadActivity + unreadAccessResponses;
  }

  static void markCurrentNotificationsRead() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return;
    if (member.role == FamilyMemberRole.owner) {
      for (final request in accessRequests) {
        if (request.status == AccessRequestStatus.pending) {
          readAccessRequestIds.add(request.id);
        }
      }
    }
    for (final notification in familyNotifications) {
      if (notification.recipientMemberId == member.id) {
        readNotificationIds.add(notification.id);
      }
    }
    for (final request in accessRequests) {
      if (request.requesterMemberId == member.id &&
          request.status != AccessRequestStatus.pending) {
        readAccessResponseIds.add(request.id);
      }
    }
    unawaited(_persistLocalFamilyNotifications());
  }

  static bool memberCanViewFeature({
    required String memberId,
    required String childId,
    required LocalPermissionFeature feature,
  }) {
    final index = familyMembers.indexWhere((member) => member.id == memberId);
    if (index < 0) return false;

    final member = familyMembers[index];
    if (member.role == FamilyMemberRole.owner) return true;

    final grant = accessGrantFor(childId, memberId);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.viewSchedule;
      case LocalPermissionFeature.homework:
        return grant.viewHomework;
      case LocalPermissionFeature.preparation:
        return grant.viewPreparation;
      case LocalPermissionFeature.exam:
        return grant.viewExam;
    }
  }

  static void recordFamilyActivity({
    required LocalPermissionFeature feature,
    required String action,
    required String title,
    required String message,
    required String childId,
    String? entityId,
    String category = '',
  }) {
    final actor = familyMemberForCurrentAccount();
    if (actor == null) return;

    final now = DateTime.now();
    final activityId = 'family-activity-${now.microsecondsSinceEpoch}';

    familyActivities.add(
      LocalFamilyActivity(
        id: activityId,
        familyId: currentFamilyId,
        actorMemberId: actor.id,
        actorName: actor.displayName,
        childId: childId,
        feature: feature,
        category: category,
        action: action,
        title: title,
        message: message,
        createdAt: now,
        entityId: entityId,
      ),
    );

    for (final member in familyMembers) {
      if (member.id == actor.id) continue;
      if (category != 'Family' &&
          !memberCanViewFeature(
            memberId: member.id,
            childId: childId,
            feature: feature,
          )) {
        continue;
      }

      final notification = LocalFamilyNotification(
        id: 'notification-${now.microsecondsSinceEpoch}-${member.id}',
        recipientMemberId: member.id,
        childId: childId,
        title: title,
        message: message,
        createdAt: now,
        entityType: category == 'Family'
            ? 'family'
            : LocalAuthorization.featureLabel(feature).toLowerCase(),
        entityId: entityId,
      );

      if (feature == LocalPermissionFeature.preparation &&
          action == 'Edited' &&
          entityId != null) {
        final existingIndex = familyNotifications.indexWhere(
          (existing) =>
              existing.recipientMemberId == member.id &&
              existing.childId == childId &&
              existing.entityType == 'preparation' &&
              existing.entityId == entityId,
        );
        if (existingIndex >= 0) {
          final oldNotification = familyNotifications[existingIndex];
          familyNotifications[existingIndex] = notification;
          readNotificationIds.remove(oldNotification.id);
          continue;
        }
      }

      familyNotifications.add(notification);
    }

    pruneNotificationInbox();
    unawaited(_persistLocalFamilyActivity());
    unawaited(_persistLocalFamilyNotifications());
  }

  static void recordFamilyManagementActivity({
    required String action,
    required String title,
    required String message,
    String? entityId,
  }) {
    recordFamilyActivity(
      feature: LocalPermissionFeature.schedule,
      action: action,
      title: title,
      message: message,
      childId: '',
      entityId: entityId,
      category: 'Family',
    );
  }

  static List<LocalFamilyNotification> notificationsForCurrentMember() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return const <LocalFamilyNotification>[];

    return familyNotifications
        .where((notification) => notification.recipientMemberId == member.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<LocalAccessRequest> responseNotificationsForCurrentMember() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return const <LocalAccessRequest>[];
    return accessRequests
        .where(
          (request) =>
              request.requesterMemberId == member.id &&
              request.status != AccessRequestStatus.pending,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static String familyAccessGrantKey(String childId, String memberId) =>
      '$childId|$memberId';

  static FamilyAccessGrant? accessGrantFor(String childId, String memberId) {
    return familyAccessGrants[familyAccessGrantKey(childId, memberId)];
  }

  static void saveAccessGrant(FamilyAccessGrant grant) {
    familyAccessGrants[familyAccessGrantKey(grant.childId, grant.memberId)] =
        grant;
    unawaited(_persistAccessGrants());
  }

  static void removeAccessGrant(String childId, String memberId) {
    familyAccessGrants.remove(familyAccessGrantKey(childId, memberId));
    unawaited(_persistAccessGrants());
  }

  /// True when Home is showing the cached family because Supabase was
  /// unreachable. Drives the offline strip on Home.
  /// Set from main() so the store can refresh the daily reminder
  /// without importing main.dart (which would create a cycle).
  static Future<void> Function()? onDataPersisted;

  static bool isOfflineData = false;

  /// Set at boot when the account signed in somewhere else, so AuthGate can
  /// tell the parent once.
  static bool otherDeviceSignIn = false;

  static String? _familyCacheKey() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    return 'bag2school_family_cache_v1_$userId';
  }

  /// Keeps the family and children on the device so a lost connection does not
  /// look like a lost family.
  static Future<void> cacheFamilySnapshot() async {
    final key = _familyCacheKey();
    if (key == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'familyId': currentFamilyId,
        'familyName': currentFamilyName,
        'activeChildId': activeChildId,
        'members': familyMembers
            .map(
              (member) => <String, dynamic>{
                'id': member.id,
                'displayName': member.displayName,
                'role': member.role.name,
                'accountId': member.accountId,
              },
            )
            .toList(),
        'children': childProfiles
            .map(
              (child) => <String, dynamic>{
                'id': child.id,
                'name': child.name,
                'grade': child.grade,
                'avatarUrl': child.avatarUrl,
                'gender': child.gender,
              },
            )
            .toList(),
      };

      await preferences.setString(key, jsonEncode(payload));
    } catch (error) {
      debugPrint('[Family] Could not cache snapshot: $error');
    }
  }

  /// Restores the last known family. Returns false when nothing is cached.
  static Future<bool> restoreFamilySnapshot() async {
    final key = _familyCacheKey();
    if (key == null) return false;

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;

      final members = (decoded['members'] as List? ?? const [])
          .whereType<Map>()
          .map((row) {
            final roleName = row['role']?.toString();
            final role = FamilyMemberRole.values.firstWhere(
              (value) => value.name == roleName,
              orElse: () => FamilyMemberRole.parentGuardian,
            );

            return FamilyMember(
              id: row['id']?.toString() ?? '',
              displayName: row['displayName']?.toString() ?? 'Family Member',
              role: role,
              accountId: row['accountId']?.toString() ?? '',
            );
          })
          .where((member) => member.id.isNotEmpty)
          .toList();

      final children = (decoded['children'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (row) => ChildProfile(
              id: row['id']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              grade: row['grade']?.toString() ?? '',
              avatarUrl: row['avatarUrl']?.toString(),
              gender: row['gender']?.toString(),
            ),
          )
          .where((child) => child.id.isNotEmpty)
          .toList();

      if (members.isEmpty && children.isEmpty) return false;

      currentFamilyId = decoded['familyId']?.toString();
      currentFamilyName = decoded['familyName']?.toString();

      familyMembers
        ..clear()
        ..addAll(members);

      childProfiles
        ..clear()
        ..addAll(children);

      final cachedActive = decoded['activeChildId']?.toString() ?? '';
      activeChildId = children.any((child) => child.id == cachedActive)
          ? cachedActive
          : (children.isEmpty ? '' : children.first.id);

      if (activeChildId.isNotEmpty) {
        await restoreActiveChildSchoolData();
      }

      isOfflineData = true;
      debugPrint('[Family] Restored the offline snapshot');
      return true;
    } catch (error) {
      debugPrint('[Family] Could not restore snapshot: $error');
      return false;
    }
  }

  // Grants live in memory during a session; this keeps them across restarts on
  // this device until they are stored in Supabase.
  static const String _accessGrantsStoragePrefix =
      'bag2school_access_grants_v1_';

  static String? _accessGrantsStorageKey() {
    final familyId = currentFamilyId;
    if (familyId == null || familyId.isEmpty) return null;
    return '$_accessGrantsStoragePrefix$familyId';
  }

  static Future<void> restoreAccessGrants() async {
    final key = _accessGrantsStorageKey();
    if (key == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      familyAccessGrants.clear();

      decoded.forEach((mapKey, value) {
        if (value is! Map) return;
        final parts = mapKey.toString().split('|');
        if (parts.length != 2) return;

        familyAccessGrants[mapKey.toString()] = FamilyAccessGrant(
          childId: parts[0],
          memberId: parts[1],
          viewSchedule: value['vs'] != false,
          editSchedule: value['es'] == true,
          viewHomework: value['vh'] != false,
          editHomework: value['eh'] == true,
          viewPreparation: value['vp'] != false,
          editPreparation: value['ep'] == true,
          viewExam: value['vx'] != false,
          editExam: value['ex'] == true,
        );
      });
    } catch (error) {
      debugPrint('[Access] Could not restore grants: $error');
    }
  }

  static Future<void> _persistAccessGrants() async {
    final key = _accessGrantsStorageKey();
    if (key == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = familyAccessGrants.map(
        (mapKey, grant) => MapEntry(mapKey, <String, bool>{
          'vs': grant.viewSchedule,
          'es': grant.editSchedule,
          'vh': grant.viewHomework,
          'eh': grant.editHomework,
          'vp': grant.viewPreparation,
          'ep': grant.editPreparation,
          'vx': grant.viewExam,
          'ex': grant.editExam,
        }),
      );

      await preferences.setString(key, jsonEncode(encoded));
    } catch (error) {
      debugPrint('[Access] Could not persist grants: $error');
    }
  }

  /// Grants the access the owner chose before sending an invitation to the
  /// members that appeared since the last load, then remembers who is here.
  static Future<void> applyPendingAccessToNewMembers() async {
    final familyId = currentFamilyId;
    if (familyId == null || familyId.isEmpty) return;

    final known = await FamilyAccessDefaults.loadKnownMembers(familyId);
    final currentIds = familyMembers.map((member) => member.id).toSet();

    // First load on this device: record who already belongs to the family and
    // grant nothing, so existing members are never changed retroactively.
    if (known.isEmpty) {
      await FamilyAccessDefaults.saveKnownMembers(familyId, currentIds);
      return;
    }

    final newMembers = familyMembers
        .where((member) => !known.contains(member.id))
        .toList();

    for (final member in newMembers) {
      final defaults = await FamilyAccessDefaults.load(
        familyId: familyId,
        role: member.role.name,
      );

      for (final entry in defaults.entries) {
        if (entry.value == MemberAccessLevel.none) {
          removeAccessGrant(entry.key, member.id);
          continue;
        }

        final full = entry.value == MemberAccessLevel.full;
        saveAccessGrant(
          FamilyAccessGrant(
            memberId: member.id,
            childId: entry.key,
            editSchedule: full,
            editHomework: full,
            editPreparation: full,
            editExam: full,
          ),
        );
      }
    }

    await FamilyAccessDefaults.saveKnownMembers(familyId, currentIds);
  }

  static final Map<String, FamilyMemberRole> childLinkedMemberRoles =
      <String, FamilyMemberRole>{};

  static final Map<String, ChildAccessSettings> childAccessDefaults =
      <String, ChildAccessSettings>{};

  static final Map<String, _ChildDataBundle> _childDataById =
      <String, _ChildDataBundle>{};
  static const String _schoolDataStoragePrefix = 'bag2school_school_data_v1_';
  static Future<void> _schoolDataWriteQueue = Future<void>.value();
  static int _schoolDataRevision = 0;

  static ChildProfile get activeChild {
    if (childProfiles.isEmpty) {
      return const ChildProfile(
        id: '',
        name: 'Your child',
        grade: 'Sign in to add a child',
      );
    }

    return childProfiles.firstWhere(
      (child) => child.id == activeChildId,
      orElse: () => childProfiles.first,
    );
  }

  // Backward-compatible accessors used by the existing Home/Settings UI.
  static String get childName {
    if (!isSignedIn) {
      return 'Your child';
    }

    return activeChild.name;
  }

  static String get childGrade {
    if (!isSignedIn) {
      return 'Sign in to add a child';
    }

    return activeChild.grade;
  }

  static void updateActiveChild({String? name, String? grade}) {
    final index = childProfiles.indexWhere(
      (child) => child.id == activeChildId,
    );

    if (index < 0) return;

    childProfiles[index] = childProfiles[index].copyWith(
      name: name,
      grade: grade,
    );
  }

  static Future<bool> deleteActiveChild() async {
    return deleteChild(activeChildId);
  }

  static Future<bool> deleteChild(String childId) async {
    if (!isSignedIn) {
      return false;
    }

    if (childId.trim().isEmpty) {
      return false;
    }

    try {
      await Supabase.instance.client
          .from('children')
          .delete()
          .eq('id', childId);

      childProfiles.removeWhere((child) => child.id == childId);

      if (childProfiles.isEmpty) {
        activeChildId = '';
      } else if (activeChildId == childId) {
        activeChildId = childProfiles.first.id;
      }

      return true;
    } catch (error, stackTrace) {
      print('[BagiChild] Delete failed: $error');
      print(stackTrace);
      return false;
    }
  }

  static ChildAccessSettings accessForChild(String childId) {
    return childAccessByChildId[childId] ??
        ChildAccessSettings(childId: childId);
  }

  static void updateChildAccess(ChildAccessSettings settings) {
    childAccessByChildId[settings.childId] = settings;
  }

  static void _saveActiveChildData() {
    if (activeChildId.isEmpty) return;
    final clonedOverrides = <String, List<PreparationItem>>{};
    preparationOccurrenceOverrides.forEach((key, items) {
      clonedOverrides[key] = items.map((item) => item.copyWith()).toList();
    });

    final clonedCancelledDates = <String, Set<String>>{};
    cancelledActivityDatesBySeries.forEach((key, dates) {
      clonedCancelledDates[key] = <String>{...dates};
    });

    _childDataById[activeChildId] = _ChildDataBundle(
      activities: List<BagActivity>.from(activities),
      preparations: preparations.map((item) => item.copyWith()).toList(),
      homeworks: homeworks.map((item) => item.copyWith()).toList(),
      homeworkPreparationCompletion: Map<String, bool>.from(
        homeworkPreparationCompletion,
      ),
      cancelledActivityOccurrences: <String>{...cancelledActivityOccurrences},
      cancelledActivityDatesBySeries: clonedCancelledDates,
      preparationOccurrenceCompletion: Map<String, bool>.from(
        preparationOccurrenceCompletion,
      ),
      preparationOccurrenceHidden: <String>{...preparationOccurrenceHidden},
      preparationOccurrenceOverrides: clonedOverrides,
    );
    _scheduleSchoolDataWrite();
  }

  static String? _schoolDataStorageKey(String childId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty || childId.isEmpty) return null;
    return '${_schoolDataStoragePrefix}${userId}_$childId';
  }

  /// Everything saved for another child, read from this device only.
  static Future<ChildDayData> dayDataForChild(String childId) async {
    final empty = ChildDayData(
      activities: const <BagActivity>[],
      preparations: const <PreparationItem>[],
      homeworks: const <HomeworkItem>[],
    );

    final key = _schoolDataStorageKey(childId);
    if (key == null) return empty;

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return empty;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return empty;

      List<T> parse<T>(String field, T Function(Map<String, dynamic>) build) {
        final stored = decoded[field];
        if (stored is! List) return <T>[];

        return stored
            .whereType<Map>()
            .map((item) => build(Map<String, dynamic>.from(item)))
            .toList();
      }

      return ChildDayData(
        activities: parse('activities', activityFromJson),
        preparations: parse('preparations', preparationFromJson),
        homeworks: parse('homeworks', homeworkFromJson),
      );
    } catch (error) {
      debugPrint('[Schedule] Could not read child $childId: $error');
      return empty;
    }
  }

  /// Activities saved for another child, without touching the active child.
  ///
  /// Used by the read-only "view another schedule" sheet on Home.
  static Future<List<BagActivity>> activitiesForChild(String childId) async {
    final key = _schoolDataStorageKey(childId);
    if (key == null) return const <BagActivity>[];

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return const <BagActivity>[];

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <BagActivity>[];

      final stored = decoded['activities'];
      if (stored is! List) return const <BagActivity>[];

      return stored
          .whereType<Map>()
          .map((item) => activityFromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      debugPrint('[Schedule] Could not read child $childId: $error');
      return const <BagActivity>[];
    }
  }

  static Future<void> restoreActiveChildSchoolData() async {
    final childId = activeChildId;
    final key = _schoolDataStorageKey(childId);
    if (key == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) {
        _loadChildData(childId);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final bundle = _ChildDataBundle.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _childDataById[childId] = bundle;
      if (activeChildId == childId) _loadChildData(childId);
      debugPrint('[LocalData] Restored school data for child $childId');
    } catch (error, stackTrace) {
      debugPrint('[LocalData] Could not restore child data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> persistActiveChildSchoolData() async {
    if (activeChildId.isEmpty) return;
    _saveActiveChildData();
    await flushSchoolDataWrites();
  }

  static void persistSchoolDataSoon() {
    if (activeChildId.isEmpty) return;
    _saveActiveChildData();
    // Tomorrow's reminder text follows the saved schedule.
    unawaited(onDataPersisted?.call() ?? Future<void>.value());
  }

  static void _scheduleSchoolDataWrite() {
    final childId = activeChildId;
    final key = _schoolDataStorageKey(childId);
    if (key == null) return;
    final revision = ++_schoolDataRevision;
    _schoolDataWriteQueue = _schoolDataWriteQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        final bundle = _childDataById[childId];
        if (bundle == null) return;
        await preferences.setString(key, jsonEncode(bundle.toJson()));
        if (revision == _schoolDataRevision) {
          debugPrint('[LocalData] Saved school data for child $childId');
        }
      } catch (error, stackTrace) {
        debugPrint('[LocalData] Could not save child data: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  static Future<void> flushSchoolDataWrites() => _schoolDataWriteQueue;

  static void _clearActiveChildData() {
    activities.clear();
    preparations.clear();
    homeworks.clear();
    homeworkPreparationCompletion.clear();
    cancelledActivityOccurrences.clear();
    cancelledActivityDatesBySeries.clear();
    preparationOccurrenceCompletion.clear();
    preparationOccurrenceHidden.clear();
    preparationOccurrenceOverrides.clear();
  }

  static void _loadChildData(String childId) {
    _clearActiveChildData();

    final data = _childDataById[childId];
    if (data == null) return;

    activities.addAll(data.activities);
    preparations.addAll(data.preparations);
    homeworks.addAll(data.homeworks);
    homeworkPreparationCompletion.addAll(data.homeworkPreparationCompletion);
    cancelledActivityOccurrences.addAll(data.cancelledActivityOccurrences);
    data.cancelledActivityDatesBySeries.forEach((key, dates) {
      cancelledActivityDatesBySeries[key] = <String>{...dates};
    });
    preparationOccurrenceCompletion.addAll(
      data.preparationOccurrenceCompletion,
    );
    preparationOccurrenceHidden.addAll(data.preparationOccurrenceHidden);
    data.preparationOccurrenceOverrides.forEach((key, items) {
      preparationOccurrenceOverrides[key] = items
          .map((item) => item.copyWith())
          .toList();
    });
  }

  static void switchActiveChild(String childId) {
    if (childId == activeChildId) return;

    final exists = childProfiles.any((child) => child.id == childId);
    if (!exists) return;

    // Preserve current child's current in-memory data before switching.
    _saveActiveChildData();

    activeChildId = childId;
    _loadChildData(childId);
    unawaited(restoreActiveChildSchoolData());
  }

  static String languageCode = 'en';

  static final List<BagActivity> activities = <BagActivity>[];
  static final List<PreparationItem> preparations = <PreparationItem>[];
  static final List<HomeworkItem> homeworks = <HomeworkItem>[];

  // Homework completion (done with the homework) is intentionally separate
  // from Homework-as-Preparation readiness (packed/prepared for the activity).
  // Key: dayOnly|homeworkId.
  static final Map<String, bool> homeworkPreparationCompletion =
      <String, bool>{};

  // A recurring activity can be cancelled for one occurrence without
  // deleting the underlying recurring series. Key: dayOnly|activityId.
  static final Set<String> cancelledActivityOccurrences = <String>{};

  // Robust occurrence cancellation store. The activity id is the series
  // identity and each date is cancelled independently. This prevents
  // deleting one occurrence from ever mutating/removing the parent series.
  static final Map<String, Set<String>> cancelledActivityDatesBySeries =
      <String, Set<String>>{};

  static void cancelActivityOccurrence(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    cancelledActivityDatesBySeries
        .putIfAbsent(activityId, () => <String>{})
        .add(clean.toIso8601String());
    // Keep the legacy set in sync for backward compatibility.
    cancelledActivityOccurrences.add(activityOccurrenceKey(clean, activityId));
  }

  static bool isOccurrenceCancelled(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    final dates = cancelledActivityDatesBySeries[activityId];
    if (dates != null && dates.contains(clean.toIso8601String())) return true;
    return cancelledActivityOccurrences.contains(
      activityOccurrenceKey(clean, activityId),
    );
  }

  static void moveCancelledOccurrences(
    String oldActivityId,
    String newActivityId,
    DateTime fromDate,
  ) {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final oldDates = cancelledActivityDatesBySeries[oldActivityId];
    if (oldDates == null || oldDates.isEmpty) return;
    final moved = <String>{};
    for (final raw in oldDates.toList()) {
      final date = DateTime.tryParse(raw);
      if (date != null && !date.isBefore(from)) {
        moved.add(raw);
        oldDates.remove(raw);
        cancelledActivityOccurrences.remove(
          activityOccurrenceKey(date, oldActivityId),
        );
        cancelledActivityOccurrences.add(
          activityOccurrenceKey(date, newActivityId),
        );
      }
    }
    if (moved.isNotEmpty) {
      cancelledActivityDatesBySeries
          .putIfAbsent(newActivityId, () => <String>{})
          .addAll(moved);
    }
  }

  static String activityOccurrenceKey(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    return '${clean.toIso8601String()}|$activityId';
  }

  static bool isActivityOccurrenceCancelled(DateTime date, String activityId) =>
      cancelledActivityOccurrences.contains(
        activityOccurrenceKey(date, activityId),
      );

  static final Map<String, bool> preparationOccurrenceCompletion =
      <String, bool>{};

  // Legacy per-item hide state kept for backward compatibility with older
  // V3 data. New occurrence edits use the full-list override below.
  static final Set<String> preparationOccurrenceHidden = <String>{};

  // IMPORTANT: a recurring activity has a base preparation template, but
  // every calendar occurrence can be edited independently. Once an
  // occurrence is edited, this map becomes the source of truth for that
  // date/activity pair. An empty list means "intentionally no preparation".
  static final Map<String, List<PreparationItem>>
  preparationOccurrenceOverrides = <String, List<PreparationItem>>{};

  static String preparationOccurrenceKey(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    return '${clean.toIso8601String()}|$activityId';
  }

  static bool hasPreparationOccurrenceOverride(
    DateTime date,
    String activityId,
  ) {
    return preparationOccurrenceOverrides.containsKey(
      preparationOccurrenceKey(date, activityId),
    );
  }

  static List<PreparationItem> preparationsForOccurrence(
    DateTime date,
    String activityId,
  ) {
    final clean = DateTime(date.year, date.month, date.day);
    final key = preparationOccurrenceKey(clean, activityId);

    if (preparationOccurrenceOverrides.containsKey(key)) {
      return preparationOccurrenceOverrides[key]!
          .map((item) => item.copyWith(preparationDate: clean))
          .toList();
    }

    final activity = activities.cast<BagActivity?>().firstWhere(
      (item) => item?.id == activityId,
      orElse: () => null,
    );

    return preparations
        .where((item) => item.activityId == activityId)
        .where((item) {
          final savedDate = DateTime(
            item.preparationDate.year,
            item.preparationDate.month,
            item.preparationDate.day,
          );

          // Non-recurring activity: preparation belongs to its saved day.
          // Recurring activity: the saved preparation is the template and
          // appears on each matching occurrence.
          final matchesActivityOccurrence =
              activity != null && activity.occursOn(clean);

          if (!matchesActivityOccurrence) {
            return savedDate == clean;
          }

          return true;
        })
        .where((item) {
          final occurrenceItemKey = '${clean.toIso8601String()}|${item.id}';
          return !preparationOccurrenceHidden.contains(occurrenceItemKey);
        })
        .map((item) => item.copyWith(preparationDate: clean))
        .toList();
  }
}
