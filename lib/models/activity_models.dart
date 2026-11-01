import 'package:flutter/material.dart';

// Extracted from lib/main.dart (14 declarations).
// Part of the staged split described in docs/knowledge-graph.md.

enum ActivityType { school, lesson, extracurricular, exam, event }

enum RecurrenceType { none, daily, weekdays, weekly, biweekly, monthly, custom }

enum ActivityIndicatorType {
  none,
  activity,
  homework,
  exam,
  event,
  preparation,
  overdue,
}

enum IndicatorType { activity, homework, exam, event, preparation, overdue }

class TimeOfDayData {
  final int hour;
  final int minute;

  const TimeOfDayData({required this.hour, required this.minute});

  int get totalMinutes => hour * 60 + minute;
}

class ActivityRecurrence {
  final RecurrenceType type;
  final int interval;
  final List<int> weekdays; // DateTime.monday ... DateTime.sunday
  final DateTime? endDate;

  const ActivityRecurrence({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.weekdays = const [],
    this.endDate,
  });

  bool occursOn(DateTime date, DateTime startDate) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    if (day.isBefore(start)) {
      return false;
    }

    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);

      if (day.isAfter(end)) {
        return false;
      }
    }

    final difference = day.difference(start).inDays;

    switch (type) {
      case RecurrenceType.none:
        return difference == 0;

      case RecurrenceType.daily:
        return difference % interval == 0;

      case RecurrenceType.weekdays:
        return day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;

      case RecurrenceType.weekly:
        return day.weekday == start.weekday && difference % (7 * interval) == 0;

      case RecurrenceType.biweekly:
        return day.weekday == start.weekday && difference % 14 == 0;

      case RecurrenceType.monthly:
        return day.day == start.day &&
            difference >= 0 &&
            _monthsBetween(start, day) % interval == 0;

      case RecurrenceType.custom:
        if (weekdays.isEmpty) {
          return false;
        }

        return weekdays.contains(day.weekday) &&
            difference >= 0 &&
            _weeksBetween(start, day) % interval == 0;
    }
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }

  int _weeksBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays ~/ 7;
  }
}

class HomeworkDetails {
  final String subject;
  final String task;
  final DateTime dueDate;
  final String notes;
  final bool completed;

  const HomeworkDetails({
    required this.subject,
    required this.task,
    required this.dueDate,
    this.notes = '',
    this.completed = false,
  });

  HomeworkDetails copyWith({
    String? subject,
    String? task,
    DateTime? dueDate,
    String? notes,
    bool? completed,
  }) {
    return HomeworkDetails(
      subject: subject ?? this.subject,
      task: task ?? this.task,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }
}

class BagActivity {
  final String id;
  final String title;
  final ActivityType type;
  final DateTime startDate;
  final TimeOfDayData startTime;
  final TimeOfDayData endTime;
  final ActivityRecurrence recurrence;
  final bool isRoutine;
  final bool showIndicator;
  final ActivityIndicatorType indicatorType;
  final bool completed;
  final String location;
  final String notes;
  final HomeworkDetails? homework;

  const BagActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    this.recurrence = const ActivityRecurrence(),
    this.isRoutine = false,
    this.showIndicator = true,
    this.indicatorType = ActivityIndicatorType.activity,
    this.completed = false,
    this.location = '',
    this.notes = '',
    this.homework,
  });

  bool occursOn(DateTime date) {
    return recurrence.occursOn(date, startDate);
  }

  int startMinutes() {
    return startTime.hour * 60 + startTime.minute;
  }

  int endMinutes() {
    return endTime.hour * 60 + endTime.minute;
  }

  BagActivity copyWith({
    String? title,
    ActivityType? type,
    DateTime? startDate,
    TimeOfDayData? startTime,
    TimeOfDayData? endTime,
    ActivityRecurrence? recurrence,
    bool? isRoutine,
    bool? showIndicator,
    ActivityIndicatorType? indicatorType,
    bool? completed,
    String? location,
    String? notes,
    HomeworkDetails? homework,
  }) {
    return BagActivity(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrence: recurrence ?? this.recurrence,
      isRoutine: isRoutine ?? this.isRoutine,
      showIndicator: showIndicator ?? this.showIndicator,
      indicatorType: indicatorType ?? this.indicatorType,
      completed: completed ?? this.completed,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      homework: homework ?? this.homework,
    );
  }
}

class PreparationItem {
  final String id;
  final String activityId;
  final String title;
  final DateTime preparationDate;
  final bool completed;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final int reminderHour;
  final int reminderMinute;

  const PreparationItem({
    required this.id,
    required this.activityId,
    required this.title,
    required this.preparationDate,
    this.completed = false,
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderHour = 18,
    this.reminderMinute = 0,
  });

  PreparationItem copyWith({
    String? title,
    DateTime? preparationDate,
    bool? completed,
    bool? reminderEnabled,
    DateTime? reminderDate,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return PreparationItem(
      id: id,
      activityId: activityId,
      title: title ?? this.title,
      preparationDate: preparationDate ?? this.preparationDate,
      completed: completed ?? this.completed,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  bool occursOn(DateTime date) {
    final a = DateTime(
      preparationDate.year,
      preparationDate.month,
      preparationDate.day,
    );
    final b = DateTime(date.year, date.month, date.day);
    return a == b;
  }
}

class HomeworkItem {
  final String id;
  final String task;
  final String subject;
  final DateTime dueDate;
  final TimeOfDayData? dueTime;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final int reminderHour;
  final int reminderMinute;
  final String notes;
  final String? relatedActivityId;
  final bool completed;
  final DateTime createdAt;

  const HomeworkItem({
    required this.id,
    required this.task,
    required this.subject,
    required this.dueDate,
    this.dueTime,
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderHour = 18,
    this.reminderMinute = 30,
    this.notes = '',
    this.relatedActivityId,
    this.completed = false,
    required this.createdAt,
  });

  HomeworkItem copyWith({
    String? task,
    String? subject,
    DateTime? dueDate,
    TimeOfDayData? dueTime,
    bool clearDueTime = false,
    bool? reminderEnabled,
    DateTime? reminderDate,
    bool clearReminderDate = false,
    int? reminderHour,
    int? reminderMinute,
    String? notes,
    String? relatedActivityId,
    bool clearRelatedActivity = false,
    bool? completed,
  }) {
    return HomeworkItem(
      id: id,
      task: task ?? this.task,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: clearReminderDate
          ? null
          : (reminderDate ?? this.reminderDate),
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      notes: notes ?? this.notes,
      relatedActivityId: clearRelatedActivity
          ? null
          : (relatedActivityId ?? this.relatedActivityId),
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}

class ActivityConflict {
  final BagActivity existingActivity;
  final DateTime date;
  final String message;

  const ActivityConflict({
    required this.existingActivity,
    required this.date,
    required this.message,
  });
}

class ActivityConflictDetector {
  const ActivityConflictDetector();

  List<ActivityConflict> findConflicts({
    required BagActivity candidate,
    required List<BagActivity> existingActivities,
  }) {
    final conflicts = <ActivityConflict>[];

    for (final existing in existingActivities) {
      if (existing.id == candidate.id) {
        continue;
      }

      final dates = _overlappingDates(candidate, existing);

      for (final date in dates) {
        final overlaps =
            candidate.startMinutes() < existing.endMinutes() &&
            candidate.endMinutes() > existing.startMinutes();

        if (overlaps) {
          conflicts.add(
            ActivityConflict(
              existingActivity: existing,
              date: date,
              message:
                  '${candidate.title} overlaps with '
                  '${existing.title}.',
            ),
          );
        }
      }
    }

    return conflicts;
  }

  List<DateTime> _overlappingDates(BagActivity first, BagActivity second) {
    final results = <DateTime>[];

    final firstStart = DateTime(
      first.startDate.year,
      first.startDate.month,
      first.startDate.day,
    );

    final secondStart = DateTime(
      second.startDate.year,
      second.startDate.month,
      second.startDate.day,
    );

    final earliest = firstStart.isAfter(secondStart) ? firstStart : secondStart;

    // For now we inspect a practical one-year window.
    // The UI will later use this same function for the
    // specific date being added/edited.
    for (var i = 0; i < 366; i++) {
      final date = earliest.add(Duration(days: i));

      if (first.occursOn(date) && second.occursOn(date)) {
        results.add(date);
      }

      if (results.length >= 20) {
        break;
      }
    }

    return results;
  }
}

class CalendarIndicator {
  final IndicatorType type;

  const CalendarIndicator(this.type);

  Color get color {
    switch (type) {
      case IndicatorType.activity:
        return const Color(0xFFFF7A21);
      case IndicatorType.homework:
        return const Color(0xFF7661D8);
      case IndicatorType.exam:
        return const Color(0xFF2A9D8F);
      case IndicatorType.event:
        return const Color(0xFF4C8FD9);
      case IndicatorType.preparation:
        return const Color(0xFF58A879);
      case IndicatorType.overdue:
        return const Color(0xFFE45757);
    }
  }
}

class ChildDayData {
  const ChildDayData({
    required this.activities,
    required this.preparations,
    required this.homeworks,
  });

  final List<BagActivity> activities;
  final List<PreparationItem> preparations;
  final List<HomeworkItem> homeworks;

  bool get isEmpty =>
      activities.isEmpty && preparations.isEmpty && homeworks.isEmpty;
}
