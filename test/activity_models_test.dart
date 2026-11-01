import 'package:bag_2_school/models/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime day(int year, int month, int date) => DateTime(year, month, date);

BagActivity activity({
  String id = 'a1',
  required DateTime start,
  ActivityRecurrence recurrence = const ActivityRecurrence(),
  int startHour = 7,
  int endHour = 8,
}) {
  return BagActivity(
    id: id,
    title: 'Activity $id',
    type: ActivityType.school,
    startDate: start,
    startTime: TimeOfDayData(hour: startHour, minute: 0),
    endTime: TimeOfDayData(hour: endHour, minute: 0),
    recurrence: recurrence,
  );
}

void main() {
  group('ActivityRecurrence', () {
    test('none only happens on the start date', () {
      const recurrence = ActivityRecurrence();
      final start = day(2026, 3, 10);

      expect(recurrence.occursOn(start, start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 11), start), isFalse);
    });

    test('nothing happens before the start date', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.daily);
      final start = day(2026, 3, 10);

      expect(recurrence.occursOn(day(2026, 3, 9), start), isFalse);
    });

    test('daily respects the interval', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.daily, interval: 2);
      final start = day(2026, 3, 10);

      expect(recurrence.occursOn(day(2026, 3, 10), start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 11), start), isFalse);
      expect(recurrence.occursOn(day(2026, 3, 12), start), isTrue);
    });

    test('weekdays covers Monday to Friday only', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.weekdays);
      final start = day(2026, 3, 9); // Monday

      expect(recurrence.occursOn(day(2026, 3, 9), start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 13), start), isTrue); // Friday
      expect(recurrence.occursOn(day(2026, 3, 14), start), isFalse); // Saturday
      expect(recurrence.occursOn(day(2026, 3, 15), start), isFalse); // Sunday
    });

    test('weekly keeps the start weekday', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.weekly);
      final start = day(2026, 3, 10); // Tuesday

      expect(recurrence.occursOn(day(2026, 3, 17), start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 18), start), isFalse);
    });

    test('biweekly skips the week in between', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.biweekly);
      final start = day(2026, 3, 10);

      expect(recurrence.occursOn(day(2026, 3, 17), start), isFalse);
      expect(recurrence.occursOn(day(2026, 3, 24), start), isTrue);
    });

    test('monthly keeps the day of the month', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.monthly);
      final start = day(2026, 1, 15);

      expect(recurrence.occursOn(day(2026, 2, 15), start), isTrue);
      expect(recurrence.occursOn(day(2026, 2, 16), start), isFalse);
    });

    test('monthly on the 31st skips months without that day', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.monthly);
      final start = day(2026, 1, 31);

      // Documented behaviour: February has no 31st, so it simply does not
      // happen there instead of sliding to the 28th.
      expect(recurrence.occursOn(day(2026, 2, 28), start), isFalse);
      expect(recurrence.occursOn(day(2026, 3, 31), start), isTrue);
    });

    test('custom uses the chosen weekdays', () {
      const recurrence = ActivityRecurrence(
        type: RecurrenceType.custom,
        weekdays: [DateTime.monday, DateTime.wednesday],
      );
      final start = day(2026, 3, 9); // Monday

      expect(recurrence.occursOn(day(2026, 3, 9), start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 11), start), isTrue);
      expect(recurrence.occursOn(day(2026, 3, 10), start), isFalse);
    });

    test('custom without weekdays never happens', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.custom);
      final start = day(2026, 3, 9);

      expect(recurrence.occursOn(start, start), isFalse);
    });

    test('end date stops the series', () {
      const recurrence = ActivityRecurrence(type: RecurrenceType.daily);
      final start = day(2026, 3, 10);
      final withEnd = ActivityRecurrence(
        type: RecurrenceType.daily,
        endDate: day(2026, 3, 12),
      );

      expect(withEnd.occursOn(day(2026, 3, 12), start), isTrue);
      expect(withEnd.occursOn(day(2026, 3, 13), start), isFalse);
      expect(recurrence.occursOn(day(2026, 3, 13), start), isTrue);
    });
  });

  group('PreparationItem', () {
    test('matches the same calendar day regardless of the time', () {
      final item = PreparationItem(
        id: 'p1',
        activityId: 'a1',
        title: 'Pack the bag',
        preparationDate: DateTime(2026, 3, 10, 21, 30),
      );

      expect(item.occursOn(DateTime(2026, 3, 10, 6)), isTrue);
      expect(item.occursOn(DateTime(2026, 3, 11, 6)), isFalse);
    });

    test('copyWith keeps the id and the activity link', () {
      final item = PreparationItem(
        id: 'p1',
        activityId: 'a1',
        title: 'Pack the bag',
        preparationDate: day(2026, 3, 10),
      );

      final done = item.copyWith(completed: true);

      expect(done.id, 'p1');
      expect(done.activityId, 'a1');
      expect(done.completed, isTrue);
      expect(done.title, 'Pack the bag');
    });
  });

  group('HomeworkItem', () {
    test('copyWith can clear the due time and the linked activity', () {
      final item = HomeworkItem(
        id: 'h1',
        task: 'Maths page 12',
        subject: 'Maths',
        dueDate: day(2026, 3, 12),
        dueTime: const TimeOfDayData(hour: 15, minute: 0),
        relatedActivityId: 'a1',
        createdAt: DateTime(2026, 3, 10, 8),
      );

      final cleared = item.copyWith(
        clearDueTime: true,
        clearRelatedActivity: true,
      );

      expect(cleared.dueTime, isNull);
      expect(cleared.relatedActivityId, isNull);
      expect(cleared.completed, isFalse);
      expect(item.dueTime, isNotNull);
    });
  });

  group('ActivityConflictDetector', () {
    const detector = ActivityConflictDetector();

    test('finds an overlapping activity on the same day', () {
      final candidate = activity(
        id: 'new',
        start: day(2026, 3, 10),
        startHour: 7,
        endHour: 8,
      );
      final existing = activity(
        id: 'old',
        start: day(2026, 3, 10),
        startHour: 7,
        endHour: 9,
      );

      final conflicts = detector.findConflicts(
        candidate: candidate,
        existingActivities: [existing],
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.existingActivity.id, 'old');
      expect(conflicts.first.date, day(2026, 3, 10));
    });

    test('back to back activities do not conflict', () {
      final candidate = activity(
        id: 'new',
        start: day(2026, 3, 10),
        startHour: 7,
        endHour: 8,
      );
      final existing = activity(
        id: 'old',
        start: day(2026, 3, 10),
        startHour: 8,
        endHour: 9,
      );

      expect(
        detector.findConflicts(
          candidate: candidate,
          existingActivities: [existing],
        ),
        isEmpty,
      );
    });

    test('the same activity never conflicts with itself', () {
      final item = activity(
        id: 'a1',
        start: day(2026, 3, 10),
        startHour: 7,
        endHour: 9,
      );

      expect(
        detector.findConflicts(
          candidate: item,
          existingActivities: [item],
        ),
        isEmpty,
      );
    });

    test('activities on different weekdays do not conflict', () {
      final candidate = activity(
        id: 'new',
        start: day(2026, 3, 10), // Tuesday, once
      );
      final existing = activity(
        id: 'old',
        start: day(2026, 3, 11), // Wednesday, once
      );

      expect(
        detector.findConflicts(
          candidate: candidate,
          existingActivities: [existing],
        ),
        isEmpty,
      );
    });

    test('repeating activities report at most twenty dates', () {
      final candidate = activity(
        id: 'new',
        start: day(2026, 3, 10),
        recurrence: const ActivityRecurrence(type: RecurrenceType.daily),
      );
      final existing = activity(
        id: 'old',
        start: day(2026, 3, 10),
        recurrence: const ActivityRecurrence(type: RecurrenceType.daily),
      );

      final conflicts = detector.findConflicts(
        candidate: candidate,
        existingActivities: [existing],
      );

      expect(conflicts, hasLength(20));
    });
  });
}
