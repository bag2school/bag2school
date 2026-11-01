import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/activity_models.dart';
import '../../models/family_models.dart';
import '../../services/bagi_message.dart';
import '../../theme/bag2school_tokens.dart';
import '../../utils/focus.dart';
import '../../widgets/bagi_character.dart';
import '../../widgets/bagi_tutorial_overlay.dart';
import '../../widgets/bubble_tail_painters.dart';
import '../../widgets/list_items.dart';
import '../../widgets/month_calendar.dart';
import '../homework/homework_page.dart';
import 'forms/school_activity_form.dart';
import 'forms/lesson_activity_form.dart';
import 'forms/exam_activity_form.dart';
import 'forms/event_activity_form.dart';
import 'forms/extracurricular_activity_form.dart';
import '../preparation/preparation_page.dart';
import '../settings/settings_page.dart';

// Schedule screen: timeline, calendar entry point and the five activity
// forms. Extracted from lib/main.dart (step 5b).

class SchedulePage extends StatefulWidget {
  final bool tutorial;
  final int tutorialStep;

  const SchedulePage({
    super.key,
    this.tutorial = false,
    this.tutorialStep = 10,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final GlobalKey _tutorialScheduleCalendarKey = GlobalKey();
  final GlobalKey _tutorialScheduleAddKey = GlobalKey();
  DateTime selectedDate = DateTime.now();

  String _bagiScheduleMessage = personalizeBagiMessage(
    "Hi {parent}! Let's see what's on your child's day. 😊",
  );
  int _bagiMessageVersion = 0;
  Timer? _bagiScheduleTimer;
  Timer? _bagiResumeTimer;
  final Random _bagiRandom = Random();
  String? _lastBagiScheduleMessage;
  String get _scheduleChildName => Bag2SchoolStore.childProfiles.isEmpty
      ? 'your child'
      : Bag2SchoolStore.childName;
  String _personalizeBagi(String message) {
    return personalizeBagiMessage(message);
  }

  // The week selector uses PageView so the dates physically follow
  // the user's finger while swiping.
  late final PageController _weekPageController;
  final int _initialWeekPage = 1000;
  late DateTime _anchorMonday;
  int _visibleWeekPage = 1000;

  @override
  void initState() {
    super.initState();

    _anchorMonday = _mondayOf(selectedDate);
    _weekPageController = PageController(initialPage: _initialWeekPage);
    _visibleWeekPage = _initialWeekPage;

    // Schedule can be created during the first frame. Start Bagi only after
    // the page has been painted so the first message is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startBagiScheduleConversation();
        if (widget.tutorial) unawaited(_runScheduleTutorial());
      }
    });
  }

  Future<void> _runScheduleTutorial() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final calendarContext = _tutorialScheduleCalendarKey.currentContext;
    if (calendarContext != null) {
      await Scrollable.ensureVisible(calendarContext, alignment: 0.2);
    }
    if (!mounted) return;
    final calendarAction = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _tutorialScheduleCalendarKey,
      stepLabel: 'Step ${widget.tutorialStep} of ${widget.tutorialStep + 7}',
      title: 'Choose a day in Schedule',
      message: 'The calendar lets you select a day and see the school activities planned for it.',
    );
    if (!mounted) return;
    if (calendarAction == BagiTutorialAction.skip) {
      Navigator.of(context).pop(false);
      return;
    }
    final addAction = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _tutorialScheduleAddKey,
      stepLabel:
          'Step ${widget.tutorialStep + 1} of ${widget.tutorialStep + 7}',
      title: 'Add a schedule',
      message: 'Tap the plus button whenever you want to add a school activity or event.',
    );
    if (mounted)
      Navigator.of(context).pop(addAction != BagiTutorialAction.skip);
  }

  void _startBagiScheduleConversation() {
    _bagiScheduleTimer?.cancel();
    _bagiResumeTimer?.cancel();
    _showNextBagiScheduleThought();
    _bagiScheduleTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _showNextBagiScheduleThought(),
    );
  }

  void _showNextBagiScheduleThought() {
    if (!mounted) return;

    final messages = <String>[
      ..._buildBagiScheduleThoughts(selectedDate),
      ..._buildBagiUpcomingReminderThoughts(selectedDate),
    ];
    if (messages.isEmpty) return;

    final candidates = messages.length > 1
        ? messages
              .where((message) => message != _lastBagiScheduleMessage)
              .toList()
        : messages;

    final message = candidates[_bagiRandom.nextInt(candidates.length)];
    _lastBagiScheduleMessage = message;
    _showBagiScheduleMessage(message);
  }

  String _bagiActivityCategory(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Class';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  List<String> _buildBagiUpcomingReminderThoughts(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final reminders = <String>[];

    // Bagi starts preparing Mom two days before an activity.
    // Example: an Aug 19 activity can be mentioned on Aug 17 and Aug 18.
    for (var daysAhead = 1; daysAhead <= 2; daysAhead++) {
      final targetDate = cleanDate.add(Duration(days: daysAhead));

      final upcoming = Bag2SchoolStore.activities
          .where((activity) => activity.occursOn(targetDate))
          .toList();

      for (final activity in upcoming) {
        final dayLabel = daysAhead == 1 ? 'tomorrow' : 'in two days';
        reminders.add(
          personalizeBagiMessage(
            "Psst, {parent}! ${activity.title} "
            "(${_bagiActivityCategory(activity)}) "
            "is coming up $dayLabel. "
            "We can get a little ready ahead of time. 😊",
          ),
        );
      }
    }

    return reminders;
  }

  List<String> _buildBagiScheduleThoughts(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);

    final activities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(date))
        .where(
          (activity) =>
              !Bag2SchoolStore.isOccurrenceCancelled(date, activity.id),
        )
        .toList();

    final preparations = Bag2SchoolStore.preparations
        .where((item) => item.occursOn(cleanDate))
        .length;
    final extras = activities.where((activity) {
      return activity.type == ActivityType.lesson ||
          activity.type == ActivityType.extracurricular ||
          activity.type == ActivityType.event;
    }).length;

    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowActivities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(tomorrow))
        .toList();
    final tomorrowExtras = tomorrowActivities.where((activity) {
      return activity.type != ActivityType.school;
    }).length;

    final messages = <String>[];

    if (preparations == 1) {
      messages.add(
        _personalizeBagi(
          "Hey {parent}! There's still one little thing to prepare for today. "
          "No rush — we can take it step by step. 🎒",
        ),
      );
    } else if (preparations > 1) {
      messages.add(
        _personalizeBagi(
          "Hey {parent}! I spotted $preparations things to prepare for today. "
          "Let's get them ready one by one. 😊",
        ),
      );
    } else {
      messages.addAll([
        _personalizeBagi(
          "Looks nice and light, {parent}! Nothing extra is asking for attention right now. ✨",
        ),
        _personalizeBagi(
          "A calm schedule today, {parent}. That's one less thing to worry about. 😊",
        ),
        _personalizeBagi(
          "We're all clear for now, {parent}! I'll keep an eye on the little details with you. 👀",
        ),
        _personalizeBagi(
          "Nice and steady, {parent}! Sometimes a quiet schedule is exactly what we need. 🌼",
        ),
      ]);
    }

    final namedExtras = activities.where((activity) {
      return activity.type == ActivityType.lesson ||
          activity.type == ActivityType.extracurricular ||
          activity.type == ActivityType.event;
    }).toList();

    if (extras == 1 && namedExtras.isNotEmpty) {
      final activity = namedExtras.first;
      messages.add(
        _personalizeBagi(
          "Hey {parent}! ${activity.title} "
          "(${_bagiActivityCategory(activity)}) "
          "is on today's list. I've got my eye on it with you. 😊",
        ),
      );
    } else if (extras > 1) {
      final preview = namedExtras
          .take(2)
          .map((activity) {
            return "${activity.title} (${_bagiActivityCategory(activity)})";
          })
          .join(' and ');

      messages.add(
        _personalizeBagi(
          "Today looks a little busy, {parent}! "
          "I spotted $extras extra activities. "
          "${preview.isEmpty ? "We'll take them one by one." : "$preview are on the radar."} 🎒",
        ),
      );
    }
    if (tomorrowExtras == 1) {
      messages.add(
        _personalizeBagi(
          "Just a little heads-up, {parent}: tomorrow has one extra activity. "
          "We can get ahead of it today. 😉",
        ),
      );
    } else if (tomorrowExtras > 1) {
      messages.add(
        _personalizeBagi(
          "Tiny heads-up for tomorrow, {parent}: there are $tomorrowExtras extra "
          "activities waiting. Let's not let them sneak up on us! 😄",
        ),
      );
    } else {
      messages.add(
        _personalizeBagi(
          "I had a quick peek at tomorrow too, {parent}. "
          "Nothing extra is waving for our attention yet. 😊",
        ),
      );
    }

    return messages;
  }

  DateTime _mondayOf(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.subtract(
      Duration(days: cleanDate.weekday - DateTime.monday),
    );
  }

  DateTime _dateForWeekPage(int page, int index) {
    final weekOffset = page - _initialWeekPage;
    return _anchorMonday.add(Duration(days: weekOffset * 7 + index));
  }

  @override
  void dispose() {
    _bagiScheduleTimer?.cancel();
    _bagiResumeTimer?.cancel();
    _weekPageController.dispose();
    super.dispose();
  }

  String _buildDateSummaryMessage(DateTime date) {
    final activities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(date))
        .where(
          (activity) =>
              !Bag2SchoolStore.isOccurrenceCancelled(date, activity.id),
        )
        .toList();

    if (activities.isEmpty) {
      return _personalizeBagi(
        "Looks like a calm day, {parent}! Nothing extra is scheduled yet. 😊",
      );
    }

    final schoolCount = activities
        .where((activity) => activity.type == ActivityType.school)
        .length;
    final lessonCount = activities
        .where((activity) => activity.type == ActivityType.lesson)
        .length;
    final extraCount = activities
        .where((activity) => activity.type == ActivityType.extracurricular)
        .length;
    final eventCount = activities
        .where((activity) => activity.type == ActivityType.event)
        .length;
    final cleanDate = DateTime(date.year, date.month, date.day);

    final preparationCount = Bag2SchoolStore.preparations
        .where((item) => item.occursOn(cleanDate))
        .length;

    final parts = <String>[];

    if (schoolCount > 0) {
      parts.add(schoolCount == 1 ? 'school' : '$schoolCount school activities');
    }
    if (lessonCount > 0) {
      parts.add(lessonCount == 1 ? 'a lesson' : '$lessonCount lessons');
    }
    if (extraCount > 0) {
      parts.add(
        extraCount == 1
            ? 'an extracurricular activity'
            : '$extraCount extracurricular activities',
      );
    }
    if (eventCount > 0) {
      parts.add(
        eventCount == 1 ? 'a school event' : '$eventCount school events',
      );
    }
    if (preparationCount > 0) {
      parts.add(
        preparationCount == 1
            ? 'something to prepare'
            : '$preparationCount things to prepare',
      );
    }

    final countText = activities.length == 1
        ? '1 activity'
        : '${activities.length} activities';

    if (parts.isEmpty) {
      return _personalizeBagi(
        "Hi {parent}! I see $countText on this day. "
        "Let's take a look together. 😊",
      );
    }

    if (parts.length == 1) {
      return _personalizeBagi(
        "Hi {parent}! This day has $countText, including ${parts.first}. "
        "Let's make sure $_scheduleChildName is ready. 🎒",
      );
    }

    final last = parts.removeLast();
    return _personalizeBagi(
      "Hi {parent}! This day has $countText: "
      "${parts.join(', ')}, and $last. "
      "Let's make sure $_scheduleChildName is ready. 🎒",
    );
  }

  void _onScheduleDateSelected(DateTime date) {
    final monday = _mondayOf(date);
    final weekDifference = monday.difference(_anchorMonday).inDays ~/ 7;
    final targetPage = _initialWeekPage + weekDifference;

    setState(() {
      selectedDate = date;
      _visibleWeekPage = targetPage;
    });

    if (_weekPageController.hasClients) {
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    _showBagiScheduleMessage(_buildDateSummaryMessage(date));
  }

  void _showBagiScheduleMessage(String message, {bool priority = false}) {
    if (priority) {
      // A confirmation is important: pause the 13-second conversation
      // so the success message gets enough time to finish.
      _bagiScheduleTimer?.cancel();
      _bagiResumeTimer?.cancel();
    }

    final version = ++_bagiMessageVersion;
    final words = message.split(' ');

    // Show the first word immediately so the bubble never gets stuck on "...".
    setState(() {
      _bagiScheduleMessage = words.isEmpty ? '' : words.first;
    });

    for (var i = 2; i <= words.length; i++) {
      Future.delayed(Duration(milliseconds: 90 * (i - 1)), () {
        if (!mounted || version != _bagiMessageVersion) return;
        setState(() {
          _bagiScheduleMessage = words.take(i).join(' ');
        });
      });
    }

    if (priority) {
      // Give Mom a comfortable pause after the confirmation, then resume
      // the normal 13-second Bagi conversation.
      _bagiResumeTimer = Timer(
        const Duration(seconds: 13),
        _startBagiScheduleConversation,
      );
    }
  }

  void _goToToday() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayMonday = _mondayOf(today);
    final weekDifference = todayMonday.difference(_anchorMonday).inDays ~/ 7;
    final targetPage = _initialWeekPage + weekDifference;

    setState(() {
      selectedDate = today;
      _visibleWeekPage = targetPage;
    });

    if (_weekPageController.hasClients) {
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    _showBagiScheduleMessage(
      "We're back to today! Let's see what's on $_scheduleChildName's plate.",
    );
  }

  Widget _buildBagiHighlightedText() {
    final message = _bagiScheduleMessage.isEmpty
        ? _personalizeBagi(
            "Hi {parent}! Let's see what's on your child's day. 😊",
          )
        : _bagiScheduleMessage;

    final activityTitles =
        Bag2SchoolStore.activities
            .map((activity) => activity.title.trim())
            .where((title) => title.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));

    if (activityTitles.isEmpty) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
      );
    }

    final lowerMessage = message.toLowerCase();
    String? matchedTitle;
    int matchIndex = -1;

    for (final title in activityTitles) {
      final index = lowerMessage.indexOf(title.toLowerCase());
      if (index >= 0) {
        matchedTitle = title;
        matchIndex = index;
        break;
      }
    }

    if (matchedTitle == null) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
      );
    }

    final before = message.substring(0, matchIndex);
    final highlighted = message.substring(
      matchIndex,
      matchIndex + matchedTitle.length,
    );
    final after = message.substring(matchIndex + matchedTitle.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: const TextStyle(
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E5DD)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Bag2SchoolColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: Bag2SchoolColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing scheduled yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Bag2SchoolColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enjoy the calm day, or add one small activity to keep the week on track.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Bag2SchoolColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showAddActivityChooser,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add activity'),
            style: FilledButton.styleFrom(
              backgroundColor: Bag2SchoolColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagiScheduleBubble() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 48, height: 48, child: const BagiCharacter()),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: const Color(0xFFE0D9FF)),
                  ),
                  child: _buildBagiHighlightedText(),
                ),
                Positioned(
                  left: -7,
                  top: 13,
                  child: CustomPaint(
                    size: const Size(14, 18),
                    painter: BagiBubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityChoice(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7D2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFFFF7A21)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF756B65)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFB8ADA5)),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
          },
    );
  }

  void _afterActivitySaved(BagActivity activity) {
    Bag2SchoolStore.activities.add(activity);
    Bag2SchoolStore.persistSchoolDataSoon();

    Bag2SchoolStore.recordFamilyActivity(
      feature: activity.type == ActivityType.exam
          ? LocalPermissionFeature.exam
          : LocalPermissionFeature.schedule,
      action: 'Added',
      title: 'Schedule added',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'added ${Bag2SchoolStore.activeChild.name} [${activity.title}].',
      childId: Bag2SchoolStore.activeChildId,
      entityId: activity.id,
    );

    if (!mounted) return;
    setState(() {});

    // Rebuild once again after the dialog route has closed.
    // This prevents a newly added one-time Exam from appearing only
    // after another Activity triggers a later rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    final category = _bagiActivityCategory(activity);
    final message = switch (activity.type) {
      ActivityType.school => _personalizeBagi(
        "Yay, {parent}! ${activity.title} is all set for School. 🏫 "
        "I'll keep it on my radar with you!",
      ),
      ActivityType.lesson => _personalizeBagi(
        "Got it, {parent}! ${activity.title} is all set as a Class. 📚 "
        "We'll keep it nice and easy!",
      ),
      ActivityType.extracurricular => _personalizeBagi(
        "Woohoo, {parent}! ${activity.title} is on the schedule. 🎉 "
        "I'll help you keep everything ready!",
      ),
      ActivityType.exam => _personalizeBagi(
        "Got it, {parent}! ${activity.title} is an Exam. 📝 "
        "I'll keep it clearly marked on the schedule.",
      ),
      _ => _personalizeBagi(
        "All set, {parent}! ${activity.title} ($category) is on the schedule. 😊 "
        "I'll keep an eye on it with you!",
      ),
    };

    // The successful-save message gets priority first. Preparation is offered
    // afterwards for every activity type, not only extracurriculars.
    _showBagiScheduleMessage(message, priority: true);
    // Let the success message finish typing and breathe for a moment before
    // opening the preparation conversation. This avoids two Bagi messages
    // competing visually.
    final messageDelay = Duration(
      milliseconds: 1200 + (message.split(' ').length * 90),
    );
    Future.delayed(messageDelay, () {
      if (!mounted) return;
      _showPreparationOffer(activity);
    });
  }

  void _showSchoolForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SchoolActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showLessonForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return LessonActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showExtracurricularForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return ExtracurricularActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showEventForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return EventActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showExamForm() {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.exam)) {
      LocalAuthorization.showDenied(context, 'add', featureLabel: 'exam');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return ExamActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showPreparationOffer(BagActivity activity) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final activityDate = DateTime(
      activity.startDate.year,
      activity.startDate.month,
      activity.startDate.day,
    );

    // Keep today's and tomorrow's preparation visible in the active
    // Preparation dashboard. Further-ahead activities default to one day before.
    final preparationDate =
        activityDate.isBefore(today.add(const Duration(days: 2)))
        ? today
        : activityDate.subtract(const Duration(days: 1));

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preparation',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: PreparationOfferCard(
              activity: activity,
              preparationDate: preparationDate,
              onNotNow: () => Navigator.pop(dialogContext),
              onAdd:
                  (
                    items,
                    reminderEnabled,
                    reminderDate,
                    reminderHour,
                    reminderMinute,
                  ) {
                    if (items.isEmpty) return;

                    final now = DateTime.now().microsecondsSinceEpoch;
                    for (var i = 0; i < items.length; i++) {
                      Bag2SchoolStore.preparations.add(
                        PreparationItem(
                          id: 'preparation-$now-$i',
                          activityId: activity.id,
                          title: items[i],
                          preparationDate: preparationDate,
                          reminderEnabled: reminderEnabled,
                          reminderDate: reminderDate,
                          reminderHour: reminderHour,
                          reminderMinute: reminderMinute,
                        ),
                      );
                    }
                    Bag2SchoolStore.persistSchoolDataSoon();

                    Navigator.pop(dialogContext);

                    if (!mounted) return;
                    setState(() {});

                    final itemText = items.length == 1
                        ? items.first
                        : '${items.length} little things';

                    _showBagiScheduleMessage(
                      reminderEnabled
                          ? _personalizeBagi(
                              "You're all set, {parent}! 🎒✨ I'll remember "
                              "$itemText for ${activity.title} and remind you "
                              "when it's time to get ready. 😊",
                            )
                          : _personalizeBagi(
                              "You're all set, {parent}! 🎒✨ I've added "
                              "$itemText to the preparation list for "
                              "${activity.title}. Easy peasy! 😊",
                            ),
                      priority: true,
                    );
                  },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  String _formatFriendlyDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _activityCategoryLabel(ActivityType type) {
    switch (type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Class';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  void _showFriendlyTimeWarning() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.88, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: scale,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2D8D0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 76,
                        height: 76,
                        child: BagiCharacter(mood: BagiMood.success),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0EDFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            _personalizeBagi(
                              "Oops, {parent}! 😄 The timing is a little mixed up. "
                              "Let's make sure the class finishes after it starts.",
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4D445B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pick an end time that's later than the start time.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF756B65)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Got it, let's fix it 😊",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditActivityDialog(
    BagActivity activity, {
    DateTime? occurrenceDate,
  }) async {
    final feature = activity.type == ActivityType.exam
        ? LocalPermissionFeature.exam
        : LocalPermissionFeature.schedule;
    final featureLabel = activity.type == ActivityType.exam
        ? 'exam'
        : 'schedule';
    if (!LocalAuthorization.canEditActive(feature)) {
      LocalAuthorization.showDenied(
        context,
        'edit',
        featureLabel: featureLabel,
      );
      return;
    }
    final editOccurrenceDate = DateTime(
      (occurrenceDate ?? activity.startDate).year,
      (occurrenceDate ?? activity.startDate).month,
      (occurrenceDate ?? activity.startDate).day,
    );
    final titleController = TextEditingController(text: activity.title);
    var start = TimeOfDay(
      hour: activity.startTime.hour,
      minute: activity.startTime.minute,
    );
    var end = TimeOfDay(
      hour: activity.endTime.hour,
      minute: activity.endTime.minute,
    );
    var editRecurrenceType = activity.type == ActivityType.exam
        ? RecurrenceType.none
        : activity.recurrence.type;
    var editSelectedWeekdays = <int>{...activity.recurrence.weekdays};

    String recurrenceLabel(RecurrenceType type) {
      switch (type) {
        case RecurrenceType.none:
          return 'One time';
        case RecurrenceType.daily:
          return 'Every day';
        case RecurrenceType.weekdays:
          return 'Every weekday (Mon–Fri)';
        case RecurrenceType.weekly:
          return 'Every week';
        case RecurrenceType.biweekly:
          return 'Every 2 weeks';
        case RecurrenceType.monthly:
          return 'Every month';
        case RecurrenceType.custom:
          return 'Custom days';
      }
    }

    ActivityRecurrence buildEditedRecurrence() => ActivityRecurrence(
      type: editRecurrenceType,
      interval: activity.recurrence.interval,
      weekdays: editRecurrenceType == RecurrenceType.custom
          ? (editSelectedWeekdays.toList()..sort())
          : activity.recurrence.weekdays,
      endDate: activity.recurrence.endDate,
    );

    Future<void> pickRecurrence(StateSetter setDialogState) async {
      if (activity.type == ActivityType.exam) return;
      if (activity.type == ActivityType.exam) return;
      await settleDialogFocus();
      if (!mounted) return;
      final selected = await showDialog<RecurrenceType>(
        context: context,
        builder: (pickerContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'How often does it repeat?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in const [
                  RecurrenceType.none,
                  RecurrenceType.daily,
                  RecurrenceType.weekdays,
                  RecurrenceType.weekly,
                  RecurrenceType.biweekly,
                  RecurrenceType.monthly,
                  RecurrenceType.custom,
                ])
                  ListTile(
                    title: Text(recurrenceLabel(option)),
                    leading: Icon(
                      option == editRecurrenceType
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: const Color(0xFFFF7A21),
                    ),
                    onTap: () => Navigator.pop(pickerContext, option),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected == null) return;
      if (selected == RecurrenceType.custom) {
        final days = <int>{...editSelectedWeekdays};
        final picked = await showDialog<Set<int>>(
          context: context,
          builder: (daysContext) => StatefulBuilder(
            builder: (context, setDays) {
              const labels = <int, String>{
                DateTime.monday: 'Mon',
                DateTime.tuesday: 'Tue',
                DateTime.wednesday: 'Wed',
                DateTime.thursday: 'Thu',
                DateTime.friday: 'Fri',
                DateTime.saturday: 'Sat',
                DateTime.sunday: 'Sun',
              };
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text(
                  'Choose days',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: labels.entries.map((e) {
                    return FilterChip(
                      label: Text(e.value),
                      selected: days.contains(e.key),
                      selectedColor: const Color(0xFFFFE2CF),
                      onSelected: (v) {
                        setDays(() {
                          if (v) {
                            days.add(e.key);
                          } else {
                            days.remove(e.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await settleDialogFocus();
                      if (!daysContext.mounted) return;
                      Navigator.pop(daysContext);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: days.isEmpty
                        ? null
                        : () => Navigator.pop(daysContext, days),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
        );
        if (picked == null || picked.isEmpty) return;
        editSelectedWeekdays = {...picked};
      }
      setDialogState(() => editRecurrenceType = selected);
    }

    final existingPreparations = Bag2SchoolStore.preparationsForOccurrence(
      editOccurrenceDate,
      activity.id,
    );

    // Draft only: Cancel must not mutate shared preparation data.
    var draftOccurrencePreparations = <PreparationItem>[
      ...existingPreparations,
    ];

    var sharedPreparationDate = existingPreparations.isNotEmpty
        ? existingPreparations.first.preparationDate
        : editOccurrenceDate;

    var sharedReminderEnabled = existingPreparations.any(
      (item) => item.reminderEnabled,
    );

    var sharedReminderDate = existingPreparations.isNotEmpty
        ? (existingPreparations.first.reminderDate ?? sharedPreparationDate)
        : sharedPreparationDate;

    var sharedReminderHour = existingPreparations.isNotEmpty
        ? existingPreparations.first.reminderHour
        : 18;

    var sharedReminderMinute = existingPreparations.isNotEmpty
        ? existingPreparations.first.reminderMinute
        : 0;

    final addPreparationController = TextEditingController();
    var addingPreparationItem = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final invalidTime =
                (start.hour * 60 + start.minute) >=
                (end.hour * 60 + end.minute);

            final linkedPreparations = <PreparationItem>[
              ...draftOccurrencePreparations,
            ];

            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? start : end,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    start = picked;
                  } else {
                    end = picked;
                  }
                });
              }
            }

            Future<void> pickSharedPreparationDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: sharedPreparationDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  sharedPreparationDate = picked;
                });
              }
            }

            Future<void> pickSharedReminderDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: sharedReminderDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  sharedReminderDate = picked;
                });
              }
            }

            Future<void> pickSharedReminderTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: sharedReminderHour,
                  minute: sharedReminderMinute,
                ),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  sharedReminderHour = picked.hour;
                  sharedReminderMinute = picked.minute;
                });
              }
            }

            void removePreparation(PreparationItem item) {
              setDialogState(() {
                draftOccurrencePreparations.removeWhere((p) => p.id == item.id);
              });
            }

            Future<void> renamePreparation(PreparationItem item) async {
              final controller = TextEditingController(text: item.title);
              await showDialog<void>(
                context: context,
                builder: (renameContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text(
                      'Tweak this preparation',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'What should we call it?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await settleDialogFocus();
                          if (!renameContext.mounted) return;
                          Navigator.pop(renameContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;
                          final index = draftOccurrencePreparations.indexWhere(
                            (p) => p.id == item.id,
                          );
                          if (index >= 0) {
                            draftOccurrencePreparations[index] =
                                draftOccurrencePreparations[index].copyWith(
                                  title: value,
                                );
                          }
                          await settleDialogFocus();
                          if (!renameContext.mounted) return;
                          Navigator.pop(renameContext);
                          setDialogState(() {});
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                        ),
                        child: const Text('Looks good'),
                      ),
                    ],
                  );
                },
              );
              controller.dispose();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE9D8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_calendar_outlined,
                      color: Color(0xFFFF7A21),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Edit activity',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Activity name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _activityCategoryLabel(activity.type),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF7A21),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickTime(true),
                            child: Text(
                              'Start\n${_formatTimeOfDay24(start)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickTime(false),
                            child: Text(
                              'End\n${_formatTimeOfDay24(end)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (invalidTime) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _personalizeBagi(
                            "Oops, {parent} 😊 Let's make the end time a little later than the start time.",
                          ),
                          style: const TextStyle(
                            color: Color(0xFF8A7E76),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (activity.type != ActivityType.exam)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDE2DA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Repeat from this date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5A4B43),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Changes apply from ${_formatDateShort(editOccurrenceDate)} onward. Earlier dates stay unchanged.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF756B65),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => pickRecurrence(setDialogState),
                                child: Text(
                                  recurrenceLabel(editRecurrenceType),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Let's get ready!",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await settleDialogFocus();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              addingPreparationItem = true;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 19),
                          label: const Text('Add something'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7A21),
                          ),
                        ),
                      ],
                    ),
                    if (addingPreparationItem) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCBA9)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: addPreparationController,
                                autofocus: false,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  setDialogState(() {});
                                },
                                onSubmitted: (_) {
                                  final value = addPreparationController.text
                                      .trim();
                                  if (value.isEmpty) return;
                                  final now =
                                      DateTime.now().microsecondsSinceEpoch;
                                  draftOccurrencePreparations.add(
                                    PreparationItem(
                                      id: 'preparation-$now-edit',
                                      activityId: activity.id,
                                      title: value,
                                      preparationDate: editOccurrenceDate,
                                      reminderEnabled: sharedReminderEnabled,
                                      reminderDate: sharedReminderDate,
                                      reminderHour: sharedReminderHour,
                                      reminderMinute: sharedReminderMinute,
                                    ),
                                  );
                                  addPreparationController.clear();
                                  setDialogState(() {
                                    addingPreparationItem = false;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Jersey, water bottle...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Add',
                              onPressed:
                                  addPreparationController.text.trim().isEmpty
                                  ? null
                                  : () {
                                      final value = addPreparationController
                                          .text
                                          .trim();
                                      final now =
                                          DateTime.now().microsecondsSinceEpoch;
                                      draftOccurrencePreparations.add(
                                        PreparationItem(
                                          id: 'preparation-$now-edit',
                                          activityId: activity.id,
                                          title: value,
                                          preparationDate: editOccurrenceDate,
                                          reminderEnabled:
                                              sharedReminderEnabled,
                                          reminderDate: sharedReminderDate,
                                          reminderHour: sharedReminderHour,
                                          reminderMinute: sharedReminderMinute,
                                        ),
                                      );
                                      addPreparationController.clear();
                                      setDialogState(() {
                                        addingPreparationItem = false;
                                      });
                                    },
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFFF7A21),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cancel',
                              onPressed: () {
                                addPreparationController.clear();
                                setDialogState(() {
                                  addingPreparationItem = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFE36A55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (linkedPreparations.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          "Nothing packed yet. Add a little something and I'll help keep track of it. 😊",
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...linkedPreparations.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEDE2DA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 19,
                                color: Color(0xFFFF7A21),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Rename',
                                onPressed: () => renamePreparation(item),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 19,
                                  color: Color(0xFFFF7A21),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => removePreparation(item),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFFE36A55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDE2DA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'When should we get ready?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5A4B43),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: pickSharedPreparationDate,
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              label: Text(
                                _formatDateShort(sharedPreparationDate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: sharedReminderEnabled,
                            onChanged: (value) {
                              setDialogState(() {
                                sharedReminderEnabled = value;
                              });
                            },
                            activeColor: const Color(0xFFFF7A21),
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Want Bagi to give you a nudge?',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: const Text(
                              "I'll remind you at the right moment, so we can stay relaxed. 😊",
                            ),
                          ),
                          if (sharedReminderEnabled) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickSharedReminderDate,
                                    child: Text(
                                      _formatDateShort(sharedReminderDate),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickSharedReminderTime,
                                    child: Text(
                                      _formatTimeOfDay24(
                                        TimeOfDay(
                                          hour: sharedReminderHour,
                                          minute: sharedReminderMinute,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await settleDialogFocus();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () async {
                          if (invalidTime) {
                            _showFriendlyTimeWarning();
                            return;
                          }

                          // If the user typed a preparation but forgot to
                          // press the small check button, Save commits that draft
                          // into THIS occurrence only. It never changes the
                          // recurring template or another date.
                          final pendingPreparation = addPreparationController
                              .text
                              .trim();

                          final currentOccurrence = <PreparationItem>[
                            ...draftOccurrencePreparations,
                          ];

                          final editedOccurrence = <PreparationItem>[
                            ...currentOccurrence,
                          ];

                          if (pendingPreparation.isNotEmpty) {
                            final now = DateTime.now().microsecondsSinceEpoch;
                            editedOccurrence.add(
                              PreparationItem(
                                id: 'preparation-$now-edit-occurrence',
                                activityId: activity.id,
                                title: pendingPreparation,
                                preparationDate: editOccurrenceDate,
                                reminderEnabled: sharedReminderEnabled,
                                reminderDate: sharedReminderDate,
                                reminderHour: sharedReminderHour,
                                reminderMinute: sharedReminderMinute,
                              ),
                            );
                          }

                          final occurrenceKey =
                              Bag2SchoolStore.preparationOccurrenceKey(
                                editOccurrenceDate,
                                activity.id,
                              );
                          Bag2SchoolStore
                                  .preparationOccurrenceOverrides[occurrenceKey] =
                              editedOccurrence
                                  .map(
                                    (item) => item.copyWith(
                                      preparationDate: editOccurrenceDate,
                                      reminderEnabled: sharedReminderEnabled,
                                      reminderDate: sharedReminderDate,
                                      reminderHour: sharedReminderHour,
                                      reminderMinute: sharedReminderMinute,
                                    ),
                                  )
                                  .toList();

                          // The occurrence override is now authoritative.
                          // Clear legacy hidden markers for this occurrence
                          // because an explicit list (including empty) is the
                          // new source of truth.
                          for (final item in currentOccurrence) {
                            Bag2SchoolStore.preparationOccurrenceHidden.remove(
                              '${editOccurrenceDate.toIso8601String()}|${item.id}',
                            );
                          }
                          addPreparationController.clear();
                          addingPreparationItem = false;

                          // Let the keyboard/focus tree settle before
                          // removing the parent dialog.
                          await settleDialogFocus();
                          if (!dialogContext.mounted) return;

                          final index = Bag2SchoolStore.activities.indexWhere(
                            (item) => item.id == activity.id,
                          );
                          if (index < 0) return;

                          final editedRecurrence = buildEditedRecurrence();
                          final editedTitle = titleController.text.trim();
                          final editedStart = TimeOfDayData(
                            hour: start.hour,
                            minute: start.minute,
                          );
                          final editedEnd = TimeOfDayData(
                            hour: end.hour,
                            minute: end.minute,
                          );
                          final startDay = DateTime(
                            activity.startDate.year,
                            activity.startDate.month,
                            activity.startDate.day,
                          );
                          final future =
                              editOccurrenceDate.isAfter(startDay) &&
                              activity.recurrence.type != RecurrenceType.none;
                          final recurrenceChanged =
                              editedRecurrence.type !=
                                  activity.recurrence.type ||
                              editedRecurrence.interval !=
                                  activity.recurrence.interval ||
                              editedRecurrence.weekdays.join(',') !=
                                  activity.recurrence.weekdays.join(',');
                          final timeChanged =
                              editedStart.hour != activity.startTime.hour ||
                              editedStart.minute != activity.startTime.minute ||
                              editedEnd.hour != activity.endTime.hour ||
                              editedEnd.minute != activity.endTime.minute;
                          final titleChanged = editedTitle != activity.title;
                          if (future &&
                              (recurrenceChanged ||
                                  timeChanged ||
                                  titleChanged)) {
                            final oldEnd = editOccurrenceDate.subtract(
                              const Duration(days: 1),
                            );
                            Bag2SchoolStore.activities[index] = activity
                                .copyWith(
                                  recurrence: ActivityRecurrence(
                                    type: activity.recurrence.type,
                                    interval: activity.recurrence.interval,
                                    weekdays: activity.recurrence.weekdays,
                                    endDate: oldEnd,
                                  ),
                                );
                            final newId =
                                '${activity.id}-from-${editOccurrenceDate.microsecondsSinceEpoch}';
                            final futureRecurrence = ActivityRecurrence(
                              type: editedRecurrence.type,
                              interval: editedRecurrence.interval,
                              weekdays: editedRecurrence.weekdays,
                              endDate: null,
                            );
                            Bag2SchoolStore.activities.add(
                              BagActivity(
                                id: newId,
                                title: editedTitle,
                                type: activity.type,
                                startDate: editOccurrenceDate,
                                startTime: editedStart,
                                endTime: editedEnd,
                                recurrence: futureRecurrence,
                                isRoutine: activity.isRoutine,
                                showIndicator: activity.showIndicator,
                                indicatorType: activity.indicatorType,
                                completed: false,
                                location: activity.location,
                                notes: activity.notes,
                                homework: activity.homework,
                              ),
                            );
                            final basePrep = Bag2SchoolStore.preparations
                                .where((p) => p.activityId == activity.id)
                                .toList();
                            for (var i = 0; i < basePrep.length; i++) {
                              final p = basePrep[i];
                              Bag2SchoolStore.preparations.add(
                                PreparationItem(
                                  id: '$newId-prep-$i-${DateTime.now().microsecondsSinceEpoch}',
                                  activityId: newId,
                                  title: p.title,
                                  preparationDate: editOccurrenceDate,
                                  completed: false,
                                  reminderEnabled: p.reminderEnabled,
                                  reminderDate: p.reminderDate,
                                  reminderHour: p.reminderHour,
                                  reminderMinute: p.reminderMinute,
                                ),
                              );
                            }
                            for (
                              var i = 0;
                              i < Bag2SchoolStore.homeworks.length;
                              i++
                            ) {
                              final h = Bag2SchoolStore.homeworks[i];
                              final due = DateTime(
                                h.dueDate.year,
                                h.dueDate.month,
                                h.dueDate.day,
                              );
                              if (h.relatedActivityId == activity.id &&
                                  !due.isBefore(editOccurrenceDate))
                                Bag2SchoolStore.homeworks[i] = h.copyWith(
                                  relatedActivityId: newId,
                                );
                            }
                            final splitDay = DateTime(
                              editOccurrenceDate.year,
                              editOccurrenceDate.month,
                              editOccurrenceDate.day,
                            );

                            // Move cancelled future occurrences with the new
                            // series identity. Each cancellation remains tied to
                            // its exact date; it never changes the series itself.
                            Bag2SchoolStore.moveCancelledOccurrences(
                              activity.id,
                              newId,
                              editOccurrenceDate,
                            );

                            final overrides = <String, List<PreparationItem>>{};
                            for (final entry
                                in Bag2SchoolStore
                                    .preparationOccurrenceOverrides
                                    .entries
                                    .toList()) {
                              final suffix = '|${activity.id}';
                              if (!entry.key.endsWith(suffix)) continue;
                              final rawDate = entry.key.substring(
                                0,
                                entry.key.length - suffix.length,
                              );
                              final date = DateTime.tryParse(rawDate);
                              if (date == null || date.isBefore(splitDay))
                                continue;
                              overrides[Bag2SchoolStore.preparationOccurrenceKey(
                                date,
                                newId,
                              )] = entry.value
                                  .map(
                                    (p) => PreparationItem(
                                      id: p.id,
                                      activityId: newId,
                                      title: p.title,
                                      preparationDate: date,
                                      completed: p.completed,
                                      reminderEnabled: p.reminderEnabled,
                                      reminderDate: p.reminderDate,
                                      reminderHour: p.reminderHour,
                                      reminderMinute: p.reminderMinute,
                                    ),
                                  )
                                  .toList();
                              Bag2SchoolStore.preparationOccurrenceOverrides
                                  .remove(entry.key);
                            }
                            Bag2SchoolStore.preparationOccurrenceOverrides
                                .addAll(overrides);
                          } else {
                            Bag2SchoolStore.activities[index] = activity
                                .copyWith(
                                  title: editedTitle,
                                  startTime: editedStart,
                                  endTime: editedEnd,
                                  recurrence: editedRecurrence,
                                );
                          }

                          Bag2SchoolStore.recordFamilyActivity(
                            feature: activity.type == ActivityType.exam
                                ? LocalPermissionFeature.exam
                                : LocalPermissionFeature.schedule,
                            action: 'Edited',
                            title: 'Schedule updated',
                            message:
                                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                'updated ${Bag2SchoolStore.activeChild.name} [${titleController.text.trim()}].',
                            childId: Bag2SchoolStore.activeChildId,
                            entityId: activity.id,
                          );
                          Bag2SchoolStore.persistSchoolDataSoon();

                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          setState(() {});
                          _showBagiScheduleMessage(
                            _personalizeBagi(
                              "All fixed, {parent}! ${titleController.text.trim()} "
                              "is looking good. 😊",
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    disabledBackgroundColor: const Color(0xFFE7DCD5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Save & keep us ready'),
                ),
              ],
            );
          },
        );
      },
    );
    addPreparationController.dispose();
    titleController.dispose();
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTimeOfDay24(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDeleteActivity(BagActivity activity) {
    final feature = activity.type == ActivityType.exam
        ? LocalPermissionFeature.exam
        : LocalPermissionFeature.schedule;
    final featureLabel = activity.type == ActivityType.exam
        ? 'exam'
        : 'schedule';
    if (!LocalAuthorization.canEditActive(feature)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: featureLabel,
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.92, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: BagiCharacter(mood: BagiMood.failed),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDFF),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(19),
                              bottomLeft: Radius.circular(19),
                              bottomRight: Radius.circular(19),
                            ),
                          ),
                          child: Text(
                            _personalizeBagi(
                              "Hey {parent}, are we sure we want to remove "
                              "'${activity.title}'? I can take it off the schedule "
                              "if you're ready. 😊",
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4D445B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activity.recurrence.type != RecurrenceType.none &&
                      activity.occursOn(selectedDate)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Bag2SchoolStore.cancelActivityOccurrence(
                            selectedDate,
                            activity.id,
                          );
                          Bag2SchoolStore.persistSchoolDataSoon();
                          Bag2SchoolStore.recordFamilyActivity(
                            feature: activity.type == ActivityType.exam
                                ? LocalPermissionFeature.exam
                                : LocalPermissionFeature.schedule,
                            action: 'Deleted',
                            title: 'Schedule occurrence removed',
                            message:
                                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                'removed ${Bag2SchoolStore.activeChild.name} [${activity.title}] '
                                'for ${_formatFriendlyDate(selectedDate)}.',
                            childId: Bag2SchoolStore.activeChildId,
                            entityId: activity.id,
                          );
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          setState(() {});
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB04A),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Remove ${_formatFriendlyDate(selectedDate)} only',
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Keep it'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final activityId = activity.id;
                            Bag2SchoolStore.activities.removeWhere(
                              (item) => item.id == activityId,
                            );

                            // Remove preparations directly owned by this activity.
                            // Homework preparations use "homework:<id>", so they remain.
                            Bag2SchoolStore.preparations.removeWhere(
                              (preparation) =>
                                  preparation.activityId == activityId,
                            );
                            Bag2SchoolStore.cancelledActivityOccurrences
                                .removeWhere(
                                  (key) => key.endsWith('|${activity.id}'),
                                );
                            Bag2SchoolStore.cancelledActivityDatesBySeries
                                .remove(activity.id);
                            Bag2SchoolStore.persistSchoolDataSoon();
                            Navigator.pop(dialogContext);
                            if (!mounted) return;
                            setState(() {});
                            Bag2SchoolStore.recordFamilyActivity(
                              feature: activity.type == ActivityType.exam
                                  ? LocalPermissionFeature.exam
                                  : LocalPermissionFeature.schedule,
                              action: 'Deleted',
                              title: 'Schedule deleted',
                              message:
                                  '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                  'deleted ${Bag2SchoolStore.activeChild.name} [${activity.title}].',
                              childId: Bag2SchoolStore.activeChildId,
                              entityId: activity.id,
                            );
                            _showBagiScheduleMessage(
                              _personalizeBagi(
                                "Done, {parent}! ${activity.title} is off the schedule. 😊",
                              ),
                              priority: true,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Remove series'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<BagActivity> _savedActivitiesForSelectedDate() {
    return Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(selectedDate))
        .where(
          (activity) =>
              !Bag2SchoolStore.isOccurrenceCancelled(selectedDate, activity.id),
        )
        .toList()
      ..sort((a, b) => a.startMinutes().compareTo(b.startMinutes()));
  }

  List<HomeworkItem> _homeworkForSelectedDate() {
    final clean = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return Bag2SchoolStore.homeworks
        .where(
          (item) =>
              DateTime(
                item.dueDate.year,
                item.dueDate.month,
                item.dueDate.day,
              ) ==
              clean,
        )
        .toList()
      ..sort(
        (a, b) => (a.dueTime?.totalMinutes ?? 1440).compareTo(
          b.dueTime?.totalMinutes ?? 1440,
        ),
      );
  }

  void _openHomeworkFromSchedule(HomeworkItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeworkPage()),
    );
  }

  String _timelineType(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Lesson';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  IconData _timelineIcon(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return Icons.school_outlined;
      case ActivityType.lesson:
        return Icons.menu_book_outlined;
      case ActivityType.extracurricular:
        return Icons.sports_basketball_outlined;
      case ActivityType.exam:
        return Icons.assignment_outlined;
      case ActivityType.event:
        return Icons.event_outlined;
    }
  }

  Color _timelineBackground(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFFEEE2);
      case ActivityType.lesson:
        return const Color(0xFFF0EDFF);
      case ActivityType.extracurricular:
        return const Color(0xFFFFF0E3);
      case ActivityType.exam:
        return const Color(0xFFE5F7F5);
      case ActivityType.event:
        return const Color(0xFFEAF3FF);
    }
  }

  Color _timelineColor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFF7A21);
      case ActivityType.lesson:
        return const Color(0xFF7661D8);
      case ActivityType.extracurricular:
        return const Color(0xFFFF9B3D);
      case ActivityType.exam:
        return const Color(0xFF2A9D8F);
      case ActivityType.event:
        return const Color(0xFF4C8FD9);
    }
  }

  String _formatTimelineTime(TimeOfDayData time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String dayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return days[date.weekday - 1];
  }

  String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String fullDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  List<DateTime> get dateList {
    return List.generate(7, (index) {
      return selectedDate
          .subtract(const Duration(days: 3))
          .add(Duration(days: index));
    });
  }

  List<CalendarIndicator> _calendarIndicators(DateTime date) {
    // Month view is driven by real activities only.
    // Preparation items intentionally do NOT create calendar dots.
    final indicators = <IndicatorType>[];

    for (final activity in Bag2SchoolStore.activities) {
      if (!activity.occursOn(date) ||
          Bag2SchoolStore.isOccurrenceCancelled(date, activity.id)) {
        continue;
      }

      // Class/Lesson is always an orange activity dot.
      if (activity.type == ActivityType.lesson) {
        if (!indicators.contains(IndicatorType.activity)) {
          indicators.add(IndicatorType.activity);
        }
        continue;
      }

      if (!activity.showIndicator) {
        continue;
      }

      switch (activity.indicatorType) {
        case ActivityIndicatorType.activity:
          if (!indicators.contains(IndicatorType.activity)) {
            indicators.add(IndicatorType.activity);
          }
          break;
        case ActivityIndicatorType.homework:
          if (!indicators.contains(IndicatorType.homework)) {
            indicators.add(IndicatorType.homework);
          }
          break;
        case ActivityIndicatorType.exam:
          if (!indicators.contains(IndicatorType.exam)) {
            indicators.add(IndicatorType.exam);
          }
          break;
        case ActivityIndicatorType.event:
          if (!indicators.contains(IndicatorType.event)) {
            indicators.add(IndicatorType.event);
          }
          break;
        case ActivityIndicatorType.preparation:
          // Preparation is a checklist linked to an activity, not a
          // calendar event. It must never add a month-view dot.
          break;
        case ActivityIndicatorType.overdue:
          if (!indicators.contains(IndicatorType.overdue)) {
            indicators.add(IndicatorType.overdue);
          }
          break;
        case ActivityIndicatorType.none:
          break;
      }
    }

    final cleanDate = DateTime(date.year, date.month, date.day);
    final hasActiveHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate && !homework.completed;
    });
    final hasAnyHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate;
    });
    if (hasActiveHomework || hasAnyHomework) {
      if (!indicators.contains(IndicatorType.homework)) {
        indicators.add(IndicatorType.homework);
      }
    }

    return indicators.map((type) => CalendarIndicator(type)).toList();
  }

  Future<void> openCalendar() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Bag2SchoolMonthCalendar(selectedDate: selectedDate);
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _anchorMonday = _mondayOf(picked);
        _visibleWeekPage = _initialWeekPage;
      });

      _weekPageController.jumpToPage(_initialWeekPage);
      _showBagiScheduleMessage(_buildDateSummaryMessage(picked));
    }
  }

  @override
  void _showAddActivityChooser() {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.schedule)) {
      LocalAuthorization.showDenied(
        context,
        'add',
        featureLabel: 'schedule',
        feature: LocalPermissionFeature.schedule,
        requestEdit: true,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DDD7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What would you like to add?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF29231F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _activityChoice(
                    sheetContext,
                    Icons.school_outlined,
                    'School',
                    'Regular school schedule',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(
                        const Duration(milliseconds: 180),
                        _showSchoolForm,
                      );
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.menu_book_outlined,
                    'Lesson',
                    'English, Math, language class, etc.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(
                        const Duration(milliseconds: 180),
                        _showLessonForm,
                      );
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.sports_basketball_outlined,
                    'Extracurricular',
                    'Basketball, Taekwondo, and more',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(
                        const Duration(milliseconds: 180),
                        _showExtracurricularForm,
                      );
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.assignment_outlined,
                    'Exam',
                    'Exam, test, or school assessment',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(
                        const Duration(milliseconds: 180),
                        _showExamForm,
                      );
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.event_outlined,
                    'Event',
                    'Field trip, parent meeting, or school event',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(
                        const Duration(milliseconds: 180),
                        _showEventForm,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleChildName = Bag2SchoolStore.childProfiles.isEmpty
        ? null
        : Bag2SchoolStore.childName;

    final dayActivities = _savedActivitiesForSelectedDate();

    // Grow with the system text scale so the date strip cannot clip its
    // labels on large accessibility font sizes.
    final textScaler = MediaQuery.textScalerOf(context);
    final weekStripHeight = textScaler.scale(116);
    final calendarButtonHeight = textScaler.scale(82);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29231F),
              ),
            ),
            SizedBox(height: 2),
            Text(
              scheduleChildName == null
                  ? 'Your activities'
                  : "$scheduleChildName's activities",
              style: TextStyle(fontSize: 14, color: Color(0xFF756B65)),
            ),
          ],
        ),
      ),

      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.schedule,
        title: 'Schedule',
        featureLabel: 'Schedule',
        childId: Bag2SchoolStore.activeChildId,
        // topCenter keeps short days pinned to the top on tall windows while
        // still capping the content width on wide ones.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // DATE SELECTOR
                    // ==================================================

                    // ==================================================
                    // WEEK DATE SELECTOR
                    // PageView makes the dates follow the finger smoothly.
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            key: _tutorialScheduleCalendarKey,
                            height: weekStripHeight,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFF1E5DD),
                              ),
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: Text(
                                      '${monthName(_dateForWeekPage(_visibleWeekPage, 0).month)} ${_dateForWeekPage(_visibleWeekPage, 0).year}',
                                      key: ValueKey(
                                        '${_dateForWeekPage(_visibleWeekPage, 0).year}-${_dateForWeekPage(_visibleWeekPage, 0).month}',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF756B65),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Expanded(
                                  child: PageView.builder(
                                    controller: _weekPageController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    onPageChanged: (page) {
                                      // Swiping only changes the visible week.
                                      // The selected date/timeline stay where Mom
                                      // left them until she taps another date.
                                      setState(() {
                                        _visibleWeekPage = page;
                                      });
                                    },
                                    itemBuilder: (context, page) {
                                      final weekDates = List.generate(
                                        7,
                                        (index) =>
                                            _dateForWeekPage(page, index),
                                      );

                                      return Row(
                                        children: weekDates.map((date) {
                                          final bool isSelected =
                                              date.year == selectedDate.year &&
                                              date.month ==
                                                  selectedDate.month &&
                                              date.day == selectedDate.day;

                                          return Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                _onScheduleDateSelected(date);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFFFF7A21)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      dayName(date),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF756B65,
                                                              ),
                                                      ),
                                                    ),

                                                    const SizedBox(height: 3),

                                                    Text(
                                                      '${date.day}',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF29231F,
                                                              ),
                                                      ),
                                                    ),

                                                    const SizedBox(height: 3),

                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: _calendarIndicators(date)
                                                          .take(3)
                                                          .map(
                                                            (
                                                              indicator,
                                                            ) => Container(
                                                              width: 5,
                                                              height: 5,
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        1,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isSelected
                                                                    ? Colors
                                                                          .white
                                                                    : indicator
                                                                          .color,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // FULL CALENDAR
                        Container(
                          width: 52,
                          height: calendarButtonHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE7D2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: IconButton(
                            onPressed: openCalendar,
                            tooltip: 'Open calendar',
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFFFF7A21),
                              size: 27,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // SELECTED DATE
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _goToToday,
                          icon: const Icon(Icons.today_outlined, size: 17),
                          label: const Text('Today'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7A21),
                            side: const BorderSide(color: Color(0xFFFFC8A5)),
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fullDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF29231F),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${dayActivities.length} '
                      '${dayActivities.length == 1 ? 'activity' : 'activities'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF756B65),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildBagiScheduleBubble(),

                    // ==================================================
                    // ACTIVITIES TIMELINE
                    // ==================================================

                    // Header above this point scrolls together with the timeline, so
                    // a short window can never overflow the fixed column.
                    ...dayActivities.map(
                      (activity) => ScheduleTimelineItem(
                        time: _formatTimelineTime(activity.startTime),
                        endTime: _formatTimelineTime(activity.endTime),
                        title: activity.title,
                        type: _timelineType(activity),
                        icon: _timelineIcon(activity),
                        backgroundColor: _timelineBackground(activity),
                        iconColor: _timelineColor(activity),
                        onEdit: () => _showEditActivityDialog(
                          activity,
                          occurrenceDate: selectedDate,
                        ),
                        onDelete: () => _confirmDeleteActivity(activity),
                      ),
                    ),

                    // Bagi already has a single conversational bubble above, so an
                    // empty day gets one quiet card instead of a second greeting.
                    if (dayActivities.isEmpty) _buildEmptyScheduleCard(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      floatingActionButton:
          LocalAuthorization.canView(
            LocalPermissionFeature.schedule,
            childId: Bag2SchoolStore.activeChildId,
          )
          ? FloatingActionButton(
              key: _tutorialScheduleAddKey,
              heroTag: 'schedule_add_activity_fab',
              onPressed: _showAddActivityChooser,
              tooltip: 'Add Activity',
              backgroundColor: const Color(0xFFFF7A21),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        indicatorColor: const Color(0xFFFFE2CF),
        onDestinationSelected: (index) {
          if (index == 1) {
            return;
          }

          if (index == 0) {
            // Always return to the actual Home root.
            // This avoids exposing Preparation when Schedule
            // was opened from Preparation.
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreparationPage(
                  completed: <bool>[false, false, false],
                  onChanged: (index, value) {
                    // Preparation currently manages its own checklist state.
                    // Shared preparation data will be connected later.
                  },
                ),
              ),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeworkPage()),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            return;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Preparation',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ScheduleTimelineItem extends StatefulWidget {
  final String time;
  final String endTime;
  final String title;
  final String type;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleTimelineItem({
    super.key,
    required this.time,
    required this.endTime,
    required this.title,
    required this.type,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ScheduleTimelineItem> createState() => _ScheduleTimelineItemState();
}

class _ScheduleTimelineItemState extends State<ScheduleTimelineItem> {
  bool _showActions = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final editable = widget.onEdit != null || widget.onDelete != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF756B65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.endTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA69B94),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Gutter reserved for the dot and rail, which are painted on top.
              const SizedBox(width: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: editable
                            ? () {
                                setState(() {
                                  _showActions = !_showActions;
                                  _pressed = false;
                                });
                              }
                            : null,
                        onTapDown: editable
                            ? (_) => setState(() => _pressed = true)
                            : null,
                        onTapCancel: editable
                            ? () => setState(() => _pressed = false)
                            : null,
                        onTapUp: editable
                            ? (_) => setState(() => _pressed = false)
                            : null,
                        child: AnimatedScale(
                          scale: _pressed ? 0.985 : 1.0,
                          duration: const Duration(milliseconds: 110),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _pressed
                                  ? Color.lerp(
                                      widget.backgroundColor,
                                      Colors.black,
                                      0.035,
                                    )
                                  : widget.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _showActions
                                    ? widget.iconColor.withValues(alpha: 0.30)
                                    : Colors.transparent,
                                width: _showActions ? 1.5 : 0,
                              ),
                              boxShadow: _pressed
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.07,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: widget.iconColor,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF302722),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.time} – ${widget.endTime}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF756B65),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: widget.iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _showActions
                                      ? Icons.expand_less_rounded
                                      : Icons.chevron_right,
                                  color: widget.iconColor,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showActions && editable) ...[
                      const SizedBox(width: 8),
                      AnimatedOpacity(
                        opacity: _showActions ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActionIconButton(
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF7661D8),
                              tooltip: 'Edit',
                              onPressed: widget.onEdit,
                            ),
                            const SizedBox(height: 4),
                            ActionIconButton(
                              icon: Icons.delete_outline,
                              color: const Color(0xFFD94B4B),
                              tooltip: 'Delete',
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Rail runs from the dot to the bottom of the item, so it always
          // matches the card height at any text scale.
          Positioned(
            left: 78,
            top: 23,
            bottom: 0,
            child: Container(width: 2, color: const Color(0xFFE8DED7)),
          ),
          Positioned(
            left: 70,
            top: 5,
            width: 18,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _pressed ? 14 : 12,
                height: _pressed ? 14 : 12,
                decoration: BoxDecoration(
                  color: widget.iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withValues(
                        alpha: _pressed ? 0.40 : 0.25,
                      ),
                      blurRadius: _pressed ? 7 : 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BagiConflictCard extends StatelessWidget {
  final ActivityConflict conflict;
  final VoidCallback onKeepBoth;
  final VoidCallback onAdjust;

  const BagiConflictCard({
    required this.conflict,
    required this.onKeepBoth,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD7BF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 64, height: 64, child: const BagiCharacter()),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(19),
                      bottomLeft: Radius.circular(19),
                      bottomRight: Radius.circular(19),
                    ),
                    border: Border.all(color: const Color(0xFFE0D9FF)),
                  ),
                  child: Text(
                    personalizeBagiMessage(
                      "Hey {parent}! I think these two are meeting at the same time. "
                      "No worries 😊 Want to keep both, or shall we find a "
                      "better spot for the new one?",
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D445B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF6),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFFFF7A21),
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    conflict.existingActivity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE0A52D),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAdjust,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    side: const BorderSide(color: Color(0xFFFFC8A5)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Let me adjust',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onKeepBoth,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Keep both',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
