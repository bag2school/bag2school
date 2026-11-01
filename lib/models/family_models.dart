// Extracted from lib/main.dart (11 declarations).
// Part of the staged split described in docs/knowledge-graph.md.

enum LocalPermissionFeature { schedule, homework, preparation, exam }

enum AccessRequestStatus { pending, approved, denied }

enum FamilyMemberRole { owner, parentGuardian, caregiver, child }

enum ChildAccessMode { managed, shared, independent }

class LocalAccount {
  final String id;
  final String displayName;
  final String email;
  final String familyMemberId;
  final String authEmail;

  const LocalAccount({
    required this.id,
    required this.displayName,
    required this.email,
    required this.familyMemberId,
    required this.authEmail,
  });

  LocalAccount copyWith({
    String? displayName,
    String? email,
    String? familyMemberId,
    String? authEmail,
  }) {
    return LocalAccount(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      authEmail: authEmail ?? this.authEmail,
    );
  }
}

class FamilyMember {
  final String id;
  final String displayName;
  final FamilyMemberRole role;
  final String? accountId;

  const FamilyMember({
    required this.id,
    required this.displayName,
    required this.role,
    this.accountId,
  });

  FamilyMember copyWith({
    String? id,
    String? displayName,
    FamilyMemberRole? role,
    String? accountId,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      accountId: accountId ?? this.accountId,
    );
  }
}

class FamilyAccessGrant {
  final String memberId;
  final String childId;
  final bool viewSchedule;
  final bool editSchedule;
  final bool viewHomework;
  final bool editHomework;
  final bool viewPreparation;
  final bool editPreparation;
  final bool viewExam;
  final bool editExam;

  const FamilyAccessGrant({
    required this.memberId,
    required this.childId,
    this.viewSchedule = true,
    this.editSchedule = false,
    this.viewHomework = true,
    this.editHomework = false,
    this.viewPreparation = true,
    this.editPreparation = false,
    this.viewExam = true,
    this.editExam = false,
  });

  FamilyAccessGrant copyWith({
    String? memberId,
    String? childId,
    bool? viewSchedule,
    bool? editSchedule,
    bool? viewHomework,
    bool? editHomework,
    bool? viewPreparation,
    bool? editPreparation,
    bool? viewExam,
    bool? editExam,
  }) {
    return FamilyAccessGrant(
      memberId: memberId ?? this.memberId,
      childId: childId ?? this.childId,
      viewSchedule: viewSchedule ?? this.viewSchedule,
      editSchedule: editSchedule ?? this.editSchedule,
      viewHomework: viewHomework ?? this.viewHomework,
      editHomework: editHomework ?? this.editHomework,
      viewPreparation: viewPreparation ?? this.viewPreparation,
      editPreparation: editPreparation ?? this.editPreparation,
      viewExam: viewExam ?? this.viewExam,
      editExam: editExam ?? this.editExam,
    );
  }
}

class ChildAccessSettings {
  final String childId;
  final ChildAccessMode mode;
  final bool parentViewSchedule;
  final bool parentViewHomework;
  final bool parentViewPreparation;
  final bool parentViewExam;

  const ChildAccessSettings({
    required this.childId,
    this.mode = ChildAccessMode.managed,
    this.parentViewSchedule = true,
    this.parentViewHomework = true,
    this.parentViewPreparation = true,
    this.parentViewExam = true,
  });

  ChildAccessSettings copyWith({
    String? childId,
    ChildAccessMode? mode,
    bool? parentViewSchedule,
    bool? parentViewHomework,
    bool? parentViewPreparation,
    bool? parentViewExam,
  }) {
    return ChildAccessSettings(
      childId: childId ?? this.childId,
      mode: mode ?? this.mode,
      parentViewSchedule: parentViewSchedule ?? this.parentViewSchedule,
      parentViewHomework: parentViewHomework ?? this.parentViewHomework,
      parentViewPreparation:
          parentViewPreparation ?? this.parentViewPreparation,
      parentViewExam: parentViewExam ?? this.parentViewExam,
    );
  }
}

class LocalAccessRequest {
  final String id;
  final String requesterMemberId;
  final String childId;
  final LocalPermissionFeature feature;
  final bool requestEdit;
  final AccessRequestStatus status;
  final DateTime createdAt;

  const LocalAccessRequest({
    required this.id,
    required this.requesterMemberId,
    required this.childId,
    required this.feature,
    this.requestEdit = false,
    this.status = AccessRequestStatus.pending,
    required this.createdAt,
  });

  LocalAccessRequest copyWith({AccessRequestStatus? status}) {
    return LocalAccessRequest(
      id: id,
      requesterMemberId: requesterMemberId,
      childId: childId,
      feature: feature,
      requestEdit: requestEdit,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class LocalFamilyNotification {
  final String id;
  final String recipientMemberId;
  final String childId;
  final String title;
  final String message;
  final DateTime createdAt;
  final String entityType;
  final String? entityId;

  const LocalFamilyNotification({
    required this.id,
    required this.recipientMemberId,
    required this.childId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.entityType,
    this.entityId,
  });
}

class LocalFamilyActivity {
  final String id;
  final String? familyId;
  final String actorMemberId;
  final String childId;
  final LocalPermissionFeature feature;
  final String action;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? entityId;
  final String actorName;
  final String category;

  const LocalFamilyActivity({
    required this.id,
    this.familyId,
    required this.actorMemberId,
    required this.childId,
    required this.feature,
    required this.action,
    required this.title,
    required this.message,
    required this.createdAt,
    this.entityId,
    this.actorName = '',
    this.category = '',
  });
}
