import 'package:bag_2_school/data/serializers.dart';
import 'package:bag_2_school/models/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activityToJson / activityFromJson', () {
    test('round trip keeps every field', () {
      final original = BagActivity(
        id: 'a1',
        title: 'Swimming lesson',
        type: ActivityType.extracurricular,
        startDate: DateTime(2026, 3, 10),
        startTime: const TimeOfDayData(hour: 16, minute: 30),
        endTime: const TimeOfDayData(hour: 17, minute: 45),
        recurrence: ActivityRecurrence(
          type: RecurrenceType.custom,
          interval: 2,
          weekdays: const [DateTime.tuesday, DateTime.thursday],
          endDate: DateTime(2026, 5, 1),
        ),
        isRoutine: true,
        showIndicator: false,
        indicatorType: ActivityIndicatorType.exam,
        completed: true,
        location: 'Sports hall',
        notes: 'Bring goggles',
        homework: HomeworkDetails(
          subject: 'Sport',
          task: 'Log the laps',
          dueDate: DateTime(2026, 3, 12),
          notes: 'Short',
          completed: true,
        ),
      );

      final restored = activityFromJson(activityToJson(original));

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.startDate, original.startDate);
      expect(restored.startTime.hour, 16);
      expect(restored.startTime.minute, 30);
      expect(restored.endTime.hour, 17);
      expect(restored.endTime.minute, 45);
      expect(restored.recurrence.type, RecurrenceType.custom);
      expect(restored.recurrence.interval, 2);
      expect(restored.recurrence.weekdays, [DateTime.tuesday, DateTime.thursday]);
      expect(restored.recurrence.endDate, DateTime(2026, 5, 1));
      expect(restored.isRoutine, isTrue);
      expect(restored.showIndicator, isFalse);
      expect(restored.indicatorType, ActivityIndicatorType.exam);
      expect(restored.completed, isTrue);
      expect(restored.location, 'Sports hall');
      expect(restored.notes, 'Bring goggles');
      expect(restored.homework?.task, 'Log the laps');
      expect(restored.homework?.completed, isTrue);
    });

    test('missing optional data falls back safely', () {
      final restored = activityFromJson({'id': 'a2', 'title': 'Bare'});

      expect(restored.id, 'a2');
      expect(restored.type, ActivityType.event);
      expect(restored.recurrence.type, RecurrenceType.none);
      expect(restored.homework, isNull);
      expect(restored.showIndicator, isTrue);
    });

    test('unknown enum names fall back instead of throwing', () {
      final restored = activityFromJson({
        'id': 'a3',
        'type': 'not-a-type',
        'recurrence': {'type': 'nope'},
      });

      expect(restored.type, ActivityType.event);
      expect(restored.recurrence.type, RecurrenceType.none);
    });
  });

  group('preparationToJson / preparationFromJson', () {
    test('round trip keeps the reminder fields', () {
      final original = PreparationItem(
        id: 'p1',
        activityId: 'a1',
        title: 'Pack the swim bag',
        preparationDate: DateTime(2026, 3, 9, 20, 15),
        completed: true,
        reminderEnabled: true,
        reminderDate: DateTime(2026, 3, 9, 19),
        reminderHour: 19,
        reminderMinute: 5,
      );

      final restored = preparationFromJson(preparationToJson(original));

      expect(restored.id, original.id);
      expect(restored.activityId, original.activityId);
      expect(restored.title, original.title);
      expect(restored.preparationDate, original.preparationDate);
      expect(restored.completed, isTrue);
      expect(restored.reminderEnabled, isTrue);
      expect(restored.reminderDate, original.reminderDate);
      expect(restored.reminderHour, 19);
      expect(restored.reminderMinute, 5);
    });
  });

  group('homeworkToJson / homeworkFromJson', () {
    test('round trip keeps the due time and the linked activity', () {
      final original = HomeworkItem(
        id: 'h1',
        task: 'Maths page 12',
        subject: 'Maths',
        dueDate: DateTime(2026, 3, 12),
        dueTime: const TimeOfDayData(hour: 15, minute: 30),
        reminderEnabled: true,
        reminderDate: DateTime(2026, 3, 11, 18, 30),
        reminderHour: 18,
        reminderMinute: 30,
        notes: 'Show the working',
        relatedActivityId: 'a1',
        completed: true,
        createdAt: DateTime(2026, 3, 10, 8, 0),
      );

      final restored = homeworkFromJson(homeworkToJson(original));

      expect(restored.id, original.id);
      expect(restored.task, original.task);
      expect(restored.subject, original.subject);
      expect(restored.dueDate, original.dueDate);
      expect(restored.dueTime?.hour, 15);
      expect(restored.dueTime?.minute, 30);
      expect(restored.reminderEnabled, isTrue);
      expect(restored.reminderDate, original.reminderDate);
      expect(restored.notes, 'Show the working');
      expect(restored.relatedActivityId, 'a1');
      expect(restored.completed, isTrue);
      expect(restored.createdAt, original.createdAt);
    });

    test('a homework without due time survives the round trip', () {
      final original = HomeworkItem(
        id: 'h2',
        task: 'Read a book',
        subject: 'English',
        dueDate: DateTime(2026, 3, 12),
        createdAt: DateTime(2026, 3, 10),
      );

      final restored = homeworkFromJson(homeworkToJson(original));

      expect(restored.dueTime, isNull);
      expect(restored.relatedActivityId, isNull);
      expect(restored.completed, isFalse);
    });
  });

  group('small helpers', () {
    test('sameCalendarDay ignores the time of day', () {
      expect(
        sameCalendarDay(DateTime(2026, 3, 10, 7), DateTime(2026, 3, 10, 22)),
        isTrue,
      );
      expect(
        sameCalendarDay(DateTime(2026, 3, 10), DateTime(2026, 3, 11)),
        isFalse,
      );
    });

    test('twoDigits pads single digit values', () {
      expect(twoDigits(7), '07');
      expect(twoDigits(19), '19');
      expect(twoDigits(0), '00');
    });
  });
}
