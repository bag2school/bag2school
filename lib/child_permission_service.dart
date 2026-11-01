import 'package:supabase_flutter/supabase_flutter.dart';

class ChildPermission {
  final bool viewSchedule;
  final bool editSchedule;
  final bool viewHomework;
  final bool editHomework;
  final bool viewPreparation;
  final bool editPreparation;
  final bool viewExam;
  final bool editExam;

  const ChildPermission({
    this.viewSchedule = false,
    this.editSchedule = false,
    this.viewHomework = false,
    this.editHomework = false,
    this.viewPreparation = false,
    this.editPreparation = false,
    this.viewExam = false,
    this.editExam = false,
  });

  factory ChildPermission.fromMap(Map<String, dynamic> map) {
    return ChildPermission(
      viewSchedule: map['view_schedule'] == true,
      editSchedule: map['edit_schedule'] == true,
      viewHomework: map['view_homework'] == true,
      editHomework: map['edit_homework'] == true,
      viewPreparation: map['view_preparation'] == true,
      editPreparation: map['edit_preparation'] == true,
      viewExam: map['view_exam'] == true,
      editExam: map['edit_exam'] == true,
    );
  }

  static const empty = ChildPermission();
}

class ChildPermissionService {
  ChildPermissionService._();

  static final ChildPermissionService instance = ChildPermissionService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<ChildPermission> getPermission({
    required String childId,
    required String familyMemberId,
  }) async {
    final row = await _client
        .from('child_access_grants')
        .select(
          'view_schedule, '
          'edit_schedule, '
          'view_homework, '
          'edit_homework, '
          'view_preparation, '
          'edit_preparation, '
          'view_exam, '
          'edit_exam',
        )
        .eq('child_id', childId)
        .eq('family_member_id', familyMemberId)
        .maybeSingle();

    if (row == null) {
      return ChildPermission.empty;
    }

    return ChildPermission.fromMap(row);
  }
}
