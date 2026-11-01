import '../models/activity_models.dart';

// Extracted from lib/main.dart: JSON (de)serialisation for the models.
// Part of the staged split described in docs/knowledge-graph.md.

Map<String, dynamic> preparationToJson(PreparationItem item) => {
  'id': item.id,
  'activityId': item.activityId,
  'title': item.title,
  'preparationDate': item.preparationDate.toIso8601String(),
  'completed': item.completed,
  'reminderEnabled': item.reminderEnabled,
  'reminderDate': item.reminderDate?.toIso8601String(),
  'reminderHour': item.reminderHour,
  'reminderMinute': item.reminderMinute,
};

PreparationItem preparationFromJson(Map<String, dynamic> json) =>
    PreparationItem(
      id: json['id']?.toString() ?? '',
      activityId: json['activityId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      preparationDate:
          DateTime.tryParse(json['preparationDate']?.toString() ?? '') ??
          DateTime.now(),
      completed: json['completed'] == true,
      reminderEnabled: json['reminderEnabled'] == true,
      reminderDate: DateTime.tryParse(json['reminderDate']?.toString() ?? ''),
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 18,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> homeworkToJson(HomeworkItem item) => {
  'id': item.id,
  'task': item.task,
  'subject': item.subject,
  'dueDate': item.dueDate.toIso8601String(),
  'dueTime': item.dueTime == null
      ? null
      : {'hour': item.dueTime!.hour, 'minute': item.dueTime!.minute},
  'reminderEnabled': item.reminderEnabled,
  'reminderDate': item.reminderDate?.toIso8601String(),
  'reminderHour': item.reminderHour,
  'reminderMinute': item.reminderMinute,
  'notes': item.notes,
  'relatedActivityId': item.relatedActivityId,
  'completed': item.completed,
  'createdAt': item.createdAt.toIso8601String(),
};

HomeworkItem homeworkFromJson(Map<String, dynamic> json) {
  final dueTime = json['dueTime'] as Map?;
  return HomeworkItem(
    id: json['id']?.toString() ?? '',
    task: json['task']?.toString() ?? '',
    subject: json['subject']?.toString() ?? '',
    dueDate:
        DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
    dueTime: dueTime == null
        ? null
        : TimeOfDayData(
            hour: (dueTime['hour'] as num?)?.toInt() ?? 0,
            minute: (dueTime['minute'] as num?)?.toInt() ?? 0,
          ),
    reminderEnabled: json['reminderEnabled'] == true,
    reminderDate: DateTime.tryParse(json['reminderDate']?.toString() ?? ''),
    reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 18,
    reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 30,
    notes: json['notes']?.toString() ?? '',
    relatedActivityId: json['relatedActivityId']?.toString(),
    completed: json['completed'] == true,
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}

Map<String, dynamic> activityToJson(BagActivity item) => {
  'id': item.id,
  'title': item.title,
  'type': item.type.name,
  'startDate': item.startDate.toIso8601String(),
  'startTime': {'hour': item.startTime.hour, 'minute': item.startTime.minute},
  'endTime': {'hour': item.endTime.hour, 'minute': item.endTime.minute},
  'recurrence': {
    'type': item.recurrence.type.name,
    'interval': item.recurrence.interval,
    'weekdays': item.recurrence.weekdays,
    'endDate': item.recurrence.endDate?.toIso8601String(),
  },
  'isRoutine': item.isRoutine,
  'showIndicator': item.showIndicator,
  'indicatorType': item.indicatorType.name,
  'completed': item.completed,
  'location': item.location,
  'notes': item.notes,
  'homework': item.homework == null
      ? null
      : {
          'subject': item.homework!.subject,
          'task': item.homework!.task,
          'dueDate': item.homework!.dueDate.toIso8601String(),
          'notes': item.homework!.notes,
          'completed': item.homework!.completed,
        },
};

BagActivity activityFromJson(Map<String, dynamic> json) {
  Map<String, dynamic> map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  TimeOfDayData time(Object? value) {
    final data = map(value);
    return TimeOfDayData(
      hour: (data['hour'] as num?)?.toInt() ?? 0,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
    );
  }

  T enumValue<T extends Enum>(List<T> values, Object? value, T fallback) =>
      values.firstWhere((entry) => entry.name == value, orElse: () => fallback);

  final recurrence = map(json['recurrence']);
  final homework = json['homework'] == null ? null : map(json['homework']);
  return BagActivity(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    type: enumValue(ActivityType.values, json['type'], ActivityType.event),
    startDate:
        DateTime.tryParse(json['startDate']?.toString() ?? '') ??
        DateTime.now(),
    startTime: time(json['startTime']),
    endTime: time(json['endTime']),
    recurrence: ActivityRecurrence(
      type: enumValue(
        RecurrenceType.values,
        recurrence['type'],
        RecurrenceType.none,
      ),
      interval: (recurrence['interval'] as num?)?.toInt() ?? 1,
      weekdays: (recurrence['weekdays'] as List? ?? [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(),
      endDate: DateTime.tryParse(recurrence['endDate']?.toString() ?? ''),
    ),
    isRoutine: json['isRoutine'] == true,
    showIndicator: json['showIndicator'] != false,
    indicatorType: enumValue(
      ActivityIndicatorType.values,
      json['indicatorType'],
      ActivityIndicatorType.activity,
    ),
    completed: json['completed'] == true,
    location: json['location']?.toString() ?? '',
    notes: json['notes']?.toString() ?? '',
    homework: homework == null
        ? null
        : HomeworkDetails(
            subject: homework['subject']?.toString() ?? '',
            task: homework['task']?.toString() ?? '',
            dueDate:
                DateTime.tryParse(homework['dueDate']?.toString() ?? '') ??
                DateTime.now(),
            notes: homework['notes']?.toString() ?? '',
            completed: homework['completed'] == true,
          ),
  );
}

bool sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String twoDigits(int value) => value.toString().padLeft(2, '0');
