import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/serializers.dart';
import '../models/child_profile.dart';
import '../data/store.dart';
import 'bagi_message.dart';
import 'reminder_service.dart';

// Builds and schedules the single daily reminder. Extracted from
// lib/main.dart so screens do not depend on the entrypoint file.

Future<(String, String)> buildDailyReminderContent() async {
  final now = DateTime.now();
  final tomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  final parent = bagiAccountAddressName();

  final children = Bag2SchoolStore.childProfiles;
  final activeId = Bag2SchoolStore.activeChildId;

  ChildProfile? active;
  for (final child in children) {
    if (child.id == activeId) {
      active = child;
      break;
    }
  }
  active ??= children.isEmpty ? null : children.first;

  final lines = <String>[];

  // 1. The active child, with what still needs packing.
  if (active != null) {
    final activities =
        Bag2SchoolStore.activities
            .where((activity) => activity.occursOn(tomorrow))
            .toList()
          ..sort((a, b) => a.startMinutes().compareTo(b.startMinutes()));

    if (activities.isEmpty) {
      lines.add('${active.name} has a free day tomorrow 😴');
    } else {
      final first = activities.first;
      lines.add(
        '${active.name} starts with ${first.title} at '
        '${twoDigits(first.startTime.hour)}:'
        '${twoDigits(first.startTime.minute)}'
        '${activities.length > 1 ? ' (+${activities.length - 1} more)' : ''}.',
      );

      final pending = <String>[];
      for (final activity in activities) {
        for (final item in Bag2SchoolStore.preparationsForOccurrence(
          tomorrow,
          activity.id,
        )) {
          if (!item.completed && !pending.contains(item.title)) {
            pending.add(item.title);
          }
        }
      }
      for (final item in Bag2SchoolStore.preparations) {
        if (sameCalendarDay(item.preparationDate, tomorrow) &&
            !item.completed &&
            !pending.contains(item.title)) {
          pending.add(item.title);
        }
      }

      if (pending.isEmpty) {
        lines.add('Nothing left to pack for ${active.name} — nice work! ✅');
      } else {
        final shown = pending.take(3).join(', ');
        final extra = pending.length > 3 ? ' +${pending.length - 3} more' : '';
        lines.add('Still to pack: $shown$extra.');
      }
    }
  }

  // 2. The other children, summarised as numbers only.
  var otherChildren = 0;
  var otherActivities = 0;
  var otherHomework = 0;
  var otherPreparation = 0;

  for (final child in children) {
    if (child.id == active?.id) continue;

    final data = await Bag2SchoolStore.dayDataForChild(child.id);

    otherChildren += 1;
    otherActivities += data.activities
        .where((activity) => activity.occursOn(tomorrow))
        .length;
    otherHomework += data.homeworks
        .where(
          (item) => !item.completed && sameCalendarDay(item.dueDate, tomorrow),
        )
        .length;
    otherPreparation += data.preparations
        .where(
          (item) =>
              !item.completed &&
              sameCalendarDay(item.preparationDate, tomorrow),
        )
        .length;
  }

  if (otherChildren > 0) {
    final parts = <String>[
      if (otherActivities > 0) '$otherActivities activities',
      if (otherPreparation > 0) '$otherPreparation to pack',
      if (otherHomework > 0) '$otherHomework homework',
    ];

    if (parts.isEmpty) {
      lines.add(
        '$otherChildren other ${otherChildren == 1 ? 'child has' : 'children have'} '
        'a free day too 😊',
      );
    } else {
      lines.add(
        'Also $otherChildren other '
        '${otherChildren == 1 ? 'child' : 'children'}: ${parts.join(' · ')}.',
      );
    }
  }

  // 3. Wording, picked at random so it feels like Bagi talking.
  final titles = <String>[
    'Evening check-in, $parent! 🎒',
    'Tomorrow is almost ready 🌙',
    'Bagi stopped by with a reminder ✨',
    'A little prep now, a calm morning later 😊',
    'School tomorrow — let’s peek ahead 🎒',
    'Tiny reminder from Bagi 🌼',
    'Ready for tomorrow, $parent? 🙌',
    'One small thing before bedtime ✨',
    'Bagi is here for tomorrow’s plan 🌙',
    'Let’s make tomorrow easy 😊',
  ];
  final closings = <String>[
    'I’ll keep an eye on it with you 😊',
    'You’re doing great, one step at a time ✨',
    'Tap me whenever you want to check 🎒',
    'No rush — Bagi is right here 🌙',
    'Small steps make big mornings easier 🙌',
    'We’ve got this together 💛',
    'Sleep well once it’s all set 😴',
    'I’m proud of you for planning ahead 🌟',
    'That’s all from me tonight 😊',
    'See you tomorrow, $parent! 🎒',
  ];

  final random = Random();
  final title = titles[random.nextInt(titles.length)];
  final closing = closings[random.nextInt(closings.length)];

  return (title, <String>[...lines, closing].join('\n'));
}

Future<void> refreshDailyReminder() async {
  if (!DailyReminder.isSupported) return;

  try {
    if (!await DailyReminder.isEnabled()) {
      await DailyReminder.cancel();
      return;
    }

    final hour = await DailyReminder.reminderHour();
    final minute = await DailyReminder.reminderMinute();
    final (title, body) = await buildDailyReminderContent();

    await DailyReminder.schedule(
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
  } catch (error) {
    debugPrint('[Reminder] refresh failed: $error');
  }
}
