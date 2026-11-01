import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/store.dart';
import '../../models/activity_models.dart';
import '../../models/child_profile.dart';
import '../../models/family_models.dart';
import '../../services/bagi_greeting_service.dart';
import '../../services/bagi_message.dart';
import '../../services/owner_tutorial_state.dart';
import '../../theme/bag2school_tokens.dart';
import '../../utils/controllers.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/bagi_character.dart';
import '../../widgets/bagi_tutorial_overlay.dart';
import '../../widgets/bubble_tail_painters.dart';
import '../../widgets/child_avatar.dart';
import 'widgets/child_switcher_sheet.dart';
import '../family/family_activity_page.dart';
import '../homework/homework_page.dart';
import '../preparation/preparation_page.dart';
import '../schedule/schedule_page.dart';
import '../settings/settings_page.dart';

// Home: today and tomorrow at a glance, readiness card and shortcuts.
// Extracted from lib/main.dart (step 6).

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final GlobalKey _homeTutorialNavigationKey = GlobalKey();
  final GlobalKey _tutorialHomeProfileKey = GlobalKey();
  final GlobalKey _tutorialHomeTomorrowKey = GlobalKey();
  final GlobalKey _tutorialHomeHomeworkKey = GlobalKey();
  final GlobalKey _tutorialOtherChildrenKey = GlobalKey();
  bool _ownerTutorialStarted = false;
  bool _ownerTutorialSettingsTapPending = false;
  Future<bool?>? _ownerTutorialSettingsRoute;

  static const Color _orange = Bag2SchoolColors.orange;
  static const Color _orangeText = Bag2SchoolColors.orangeText;
  static const Color _orangeSoft = Bag2SchoolColors.orangeSoft;
  static const Color _peach = Bag2SchoolColors.peach;
  static const Color _cream = Bag2SchoolColors.warmPaper;
  static const Color _ink = Bag2SchoolColors.ink;
  static const Color _muted = Bag2SchoolColors.muted;
  static const Color _purple = Bag2SchoolColors.homework;
  static const Color _purpleText = Bag2SchoolColors.homeworkText;
  static const Color _purpleSoft = Bag2SchoolColors.homeworkSoft;
  static const Color _teal = Bag2SchoolColors.activity;

  List<String> _bagiHomeMessagesForHour(int hour) {
    final parentTitle = bagiAccountAddressName();
    final childName = Bag2SchoolStore.childName;

    final currentGreeting = BagiGreetingService.current(
      childName: childName,
      preferredTitle: parentTitle,
    );

    if (hour >= 5 && hour < 12) {
      return [
        currentGreeting,
        "Morning, $parentTitle! "
            "Let's make sure $childName starts the day feeling ready. 🎒",
        "Good morning! "
            "I'll keep an eye on the little school things with you. ✨",
      ];
    }

    if (hour >= 12 && hour < 18) {
      return [
        currentGreeting,
        "Afternoon check-in! "
            "We can get tomorrow ready little by little. 🎒",
        "Hi $parentTitle! "
            "Let's keep today's school things nice and easy. ✨",
      ];
    }

    if (hour >= 18 && hour < 21) {
      return [
        currentGreeting,
        "Evening check-in! "
            "We can finish the important little things together. 🎒",
        "Good evening! "
            "Let's make sure $childName is ready for tomorrow. ✨",
      ];
    }

    return [
      currentGreeting,
      "It's a quiet night. "
          "We can finish the important school things together. 🎒",
      "I'm here for the little things, even late at night. ✨",
    ];
  }

  Timer? _bagiHomeTimer;
  int _bagiHomeMessageIndex = 0;
  int _bagiHomeVersion = 0;
  String get _bagiHomeVisibleMessageInitial =>
      _bagiHomeMessagesForHour(DateTime.now().hour).first;

  late String _bagiHomeVisibleMessage;

  @override
  void initState() {
    super.initState();
    _bagiHomeVisibleMessage = _bagiHomeVisibleMessageInitial;
    _startBagiHomeConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeStartOwnerTutorial());
    });
  }

  @override
  void dispose() {
    _bagiHomeTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeStartOwnerTutorial() async {
    if (_ownerTutorialStarted || !mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final role = Bag2SchoolStore.familyMemberForCurrentAccount()?.role;
    if (userId == null ||
        (role != FamilyMemberRole.owner &&
            role != FamilyMemberRole.parentGuardian &&
            role != FamilyMemberRole.caregiver)) {
      return;
    }
    var shouldShow = await OwnerTutorialState.shouldShow(userId);
    if (!shouldShow &&
        !await OwnerTutorialState.isCompleted(userId) &&
        mounted) {
      await OwnerTutorialState.markPending(userId);
      shouldShow = true;
    }
    if (!mounted || !shouldShow) return;

    _ownerTutorialStarted = true;
    final needsChildSetup =
        role == FamilyMemberRole.owner && Bag2SchoolStore.childProfiles.isEmpty;
    final begin = await showBagiTutorialWelcome(
      context,
      includeChildSetup: needsChildSetup,
    );
    if (!mounted) return;
    if (begin != true) {
      await OwnerTutorialState.markCompleted(userId);
      return;
    }

    var firstHomeStep = 1;
    if (needsChildSetup) {
      _ownerTutorialSettingsTapPending = true;
      final settingsStep = await showBagiTutorialSpotlight(
        context: context,
        navigationBarKey: _homeTutorialNavigationKey,
        navigationItemIndex: 4,
        stepLabel: 'Step 1 of 17',
        title: 'Let’s set up your family',
        message: 'Start in Settings. I’ll help you add your child’s profile.',
        targetActionId: 'owner-open-settings',
      );
      if (!mounted) return;
      _ownerTutorialSettingsTapPending = false;
      if (settingsStep == BagiTutorialAction.skip) {
        await OwnerTutorialState.markCompleted(userId);
        return;
      }

      final setupComplete = settingsStep == BagiTutorialAction.targetTapped
          ? await _ownerTutorialSettingsRoute
          : await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const SettingsPage(ownerSetupTutorial: true),
              ),
            );
      if (!mounted || setupComplete != true) return;
      final homeVisible = await _waitForHomeRoute();
      if (!mounted || !homeVisible) return;
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      firstHomeStep = 7;
    }
    await _runHomeMenuTutorial(userId, firstHomeStep);
  }

  Future<bool> _waitForHomeRoute() async {
    for (var attempt = 0; attempt < 20 && mounted; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
      if (ModalRoute.of(context)?.isCurrent == true) return true;
    }
    return false;
  }

  Future<void> _runHomeMenuTutorial(String userId, int firstHomeStep) async {
    final homeTargets = <({GlobalKey key, String title, String message})>[
      (
        key: _tutorialHomeProfileKey,
        title: 'Your child’s profile',
        message: Bag2SchoolStore.childProfiles.length > 1
            ? 'The active child and the family they belong to. Tap Switch child '
                  'to move between profiles — or tap a profile in Settings.'
            : 'Your child’s name, grade and family. Switching appears once the '
                  'family has more than one profile.',
      ),
      (
        key: _tutorialHomeTomorrowKey,
        title: 'Tomorrow’s schedule',
        message:
            'This section shows the school activities planned for tomorrow.',
      ),
      (
        key: _tutorialHomeHomeworkKey,
        title: 'Homework to do',
        message: 'A quick view of unfinished homework and upcoming due dates.',
      ),
    ];

    for (var index = 0; index < homeTargets.length && mounted; index++) {
      final step = homeTargets[index];
      final targetContext = step.key.currentContext;
      if (targetContext == null) continue;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        alignment: 0.45,
      );
      if (!mounted) return;
      final action = await showBagiTutorialSpotlight(
        context: context,
        targetKey: step.key,
        stepLabel: 'Step ${firstHomeStep + index} of ${firstHomeStep + 7}',
        title: step.title,
        message: step.message,
      );
      if (!mounted) return;
      if (action == BagiTutorialAction.skip) {
        await OwnerTutorialState.markCompleted(userId);
        return;
      }
    }

    // Bonus step, only when another child profile exists.
    if (Bag2SchoolStore.childProfiles.length > 1 && mounted) {
      final otherContext = _tutorialOtherChildrenKey.currentContext;

      if (otherContext != null) {
        await Scrollable.ensureVisible(
          otherContext,
          duration: const Duration(milliseconds: 250),
          alignment: 0.8,
        );
        if (!mounted) return;

        final action = await showBagiTutorialSpotlight(
          context: context,
          targetKey: _tutorialOtherChildrenKey,
          stepLabel: 'Bonus · other children',
          title: 'Peek at another child',
          message:
              'Tap a card to see that child’s schedule for tomorrow — view only. '
              'Switch the active child when you want to make changes.',
        );
        if (action == BagiTutorialAction.skip) {
          await OwnerTutorialState.markCompleted(userId);
          return;
        }
      }
    }

    const pageTours = <({String page, int offset})>[
      (page: 'schedule', offset: 3),
      (page: 'preparation', offset: 5),
      (page: 'homework', offset: 6),
    ];
    for (final step in pageTours) {
      if (!mounted) return;
      final pageCompleted = await _pushTutorialPage(
        step.page,
        firstHomeStep,
        step.offset,
      );
      if (pageCompleted != true) {
        await OwnerTutorialState.markCompleted(userId);
        return;
      }
      if (!mounted || !await _waitForHomeRoute()) return;
    }

    if (!mounted) return;
    final showFamilyTour = await showBagiTutorialChoiceDialog(
      context: context,
      title: 'Step ${firstHomeStep + 7} · You’re all set!',
      message: 'You’ve explored the daily school tools. Would you like a quick tour of Family settings too?',
      continueLabel: 'Show me',
      skipLabel: 'Finish tutorial',
    );
    if (!mounted) return;
    if (showFamilyTour == true) {
      final familyResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            familyTutorial: true,
            familyTutorialFirstStep: firstHomeStep + 8,
          ),
        ),
      );
      if (!mounted) return;
      if (familyResult == true) await _waitForHomeRoute();
    }
    if (!mounted) return;
    await OwnerTutorialState.markCompleted(userId);
    if (!mounted) return;
    await showBagiTutorialChoiceDialog(
      context: context,
      title: 'You’re all set!',
      message: 'BAGI will be here whenever you need a hand. Enjoy exploring Bag2School!',
      continueLabel: 'Let’s go',
      skipLabel: 'Close',
    );
  }

  Future<bool?> _pushTutorialPage(String page, int firstHomeStep, int offset) {
    final route = switch (page) {
      'schedule' => MaterialPageRoute<bool>(
        builder: (_) =>
            SchedulePage(tutorial: true, tutorialStep: firstHomeStep + offset),
      ),
      'preparation' => MaterialPageRoute<bool>(
        builder: (_) => PreparationPage(
          tutorial: true,
          tutorialStep: firstHomeStep + offset,
        ),
      ),
      _ => MaterialPageRoute<bool>(
        builder: (_) =>
            HomeworkPage(tutorial: true, tutorialStep: firstHomeStep + offset),
      ),
    };
    return Navigator.of(context).push<bool>(route);
  }

  void _startBagiHomeConversation() {
    _bagiHomeTimer?.cancel();
    _bagiHomeTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _nextBagiHomeMessage(),
    );
  }

  void _nextBagiHomeMessage() {
    if (!mounted) return;
    final messages = _bagiHomeMessagesForHour(DateTime.now().hour);
    _bagiHomeMessageIndex = (_bagiHomeMessageIndex + 1) % messages.length;
    final message = messages[_bagiHomeMessageIndex];
    final version = ++_bagiHomeVersion;
    final words = message.split(' ');

    setState(() => _bagiHomeVisibleMessage = '');

    for (var i = 1; i <= words.length; i++) {
      Future.delayed(Duration(milliseconds: 70 * i), () {
        if (!mounted || version != _bagiHomeVersion) return;
        setState(() {
          _bagiHomeVisibleMessage = words.take(i).join(' ');
        });
      });
    }
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<BagActivity> _activitiesForDate(DateTime date) {
    final clean = _dayOnly(date);
    final activities =
        Bag2SchoolStore.activities
            .where((activity) => activity.occursOn(clean))
            .where(
              (activity) =>
                  !Bag2SchoolStore.isOccurrenceCancelled(clean, activity.id),
            )
            .toList()
          ..sort((a, b) => a.startMinutes().compareTo(b.startMinutes()));
    return activities;
  }

  List<PreparationItem> _preparationsForDate(DateTime date) {
    final clean = _dayOnly(date);
    final result = <PreparationItem>[];
    final added = <String>{};

    for (final activity in _activitiesForDate(clean)) {
      final items = Bag2SchoolStore.preparationsForOccurrence(
        clean,
        activity.id,
      );
      for (final item in items) {
        if (_isHomeworkPreparationHome(item)) continue;
        if (added.add('${activity.id}|${item.id}')) {
          result.add(item.copyWith(preparationDate: clean));
        }
      }
    }

    // A PreparationItem can exist in the base list even when the occurrence
    // helper returned an overridden/filtered list. Add the date-matching
    // source item for each target activity as a safe fallback.
    for (final item in Bag2SchoolStore.preparations) {
      if (_isHomeworkPreparationHome(item) || !item.occursOn(clean)) continue;
      if (!_activitiesForDate(clean).any((a) => a.id == item.activityId)) {
        continue;
      }
      if (added.add('${item.activityId}|${item.id}')) {
        result.add(item.copyWith(preparationDate: clean));
      }
    }

    return result;
  }

  HomeworkItem? _homeworkForPreparationHome(PreparationItem item) {
    for (final homework in Bag2SchoolStore.homeworks) {
      if (item.id == 'prep-${homework.id}') return homework;
    }
    return null;
  }

  bool _isHomeworkPreparationHome(PreparationItem item) =>
      _homeworkForPreparationHome(item) != null;

  bool _isPreparationChecked(PreparationItem item, DateTime date) {
    final linkedHomework = _homeworkForPreparationHome(item);
    if (linkedHomework != null) {
      final key = '${_dayOnly(date).toIso8601String()}|${linkedHomework.id}';
      return Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;
    }

    final clean = _dayOnly(date);
    final overrideItems =
        Bag2SchoolStore
            .preparationOccurrenceOverrides[Bag2SchoolStore.preparationOccurrenceKey(
          clean,
          item.activityId,
        )];

    if (overrideItems != null) {
      final overrideItem = overrideItems
          .where((entry) => entry.id == item.id)
          .cast<PreparationItem?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      if (overrideItem != null) return overrideItem.completed;
    }

    return Bag2SchoolStore
            .preparationOccurrenceCompletion['${clean.toIso8601String()}|${item.id}'] ??
        item.completed;
  }

  /// Readiness checkbox for a homework item.
  ///
  /// The explicit tick in GET READY wins; otherwise the Homework page flag is
  /// used, so the two surfaces agree.
  bool _isHomeHomeworkChecked(HomeworkItem homework) {
    final key =
        '${_dayOnly(homework.dueDate).toIso8601String()}|${homework.id}';

    return Bag2SchoolStore.homeworkPreparationCompletion[key] ??
        homework.completed;
  }

  double _readinessProgress(
    DateTime date,
    List<PreparationItem> preparations,
    List<HomeworkItem> homeworks,
  ) {
    final total = preparations.length + homeworks.length;
    if (total == 0) return 0;

    final prepDone = preparations
        .where((item) => _isPreparationChecked(item, date))
        .length;
    final homeworkDone = homeworks.where(_isHomeHomeworkChecked).length;

    return (prepDone + homeworkDone) / total;
  }

  void _toggleHomePreparation(PreparationItem item, DateTime date) {
    final clean = _dayOnly(date);
    final occurrenceKey = Bag2SchoolStore.preparationOccurrenceKey(
      clean,
      item.activityId,
    );
    final current = _isPreparationChecked(item, clean);

    setState(() {
      final overrides =
          Bag2SchoolStore.preparationOccurrenceOverrides[occurrenceKey];

      if (overrides != null) {
        final index = overrides.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          overrides[index] = overrides[index].copyWith(
            completed: !current,
            preparationDate: clean,
          );
          return;
        }
      }

      // Recurring activity: completion is occurrence-local.
      final activity = Bag2SchoolStore.activities
          .cast<BagActivity?>()
          .firstWhere(
            (entry) => entry?.id == item.activityId,
            orElse: () => null,
          );

      if (activity != null && activity.occursOn(clean)) {
        Bag2SchoolStore
                .preparationOccurrenceCompletion['${clean.toIso8601String()}|${item.id}'] =
            !current;
        return;
      }

      // One-time/standalone preparation: update the base item.
      final index = Bag2SchoolStore.preparations.indexWhere(
        (entry) => entry.id == item.id,
      );
      if (index >= 0) {
        Bag2SchoolStore.preparations[index] = Bag2SchoolStore
            .preparations[index]
            .copyWith(completed: !current, preparationDate: clean);
      }
    });
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  void _toggleHomeHomework(HomeworkItem homework) {
    final key =
        '${_dayOnly(homework.dueDate).toIso8601String()}|${homework.id}';
    final current = _isHomeHomeworkChecked(homework);

    setState(() {
      Bag2SchoolStore.homeworkPreparationCompletion[key] = !current;
    });
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  String _formatDateLong(DateTime date) {
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
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDayData time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _activityColor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return _orange;
      case ActivityType.lesson:
        return _purple;
      case ActivityType.extracurricular:
        return const Color(0xFFFF9B3D);
      case ActivityType.exam:
        return _teal;
      case ActivityType.event:
        return const Color(0xFF4C8FD9);
    }
  }

  Color _activityBackground(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFFEEE2);
      case ActivityType.lesson:
        return _purpleSoft;
      case ActivityType.extracurricular:
        return const Color(0xFFFFF0E3);
      case ActivityType.exam:
        return const Color(0xFFE5F7F5);
      case ActivityType.event:
        return const Color(0xFFEAF3FF);
    }
  }

  IconData _activityIcon(BagActivity activity) {
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

  bool get _showTodayPreparation {
    final homeNow = _homeNow;
    final nowMinutes = homeNow.hour * 60 + homeNow.minute;
    final today = _dayOnly(homeNow);

    // Preparing for an activity that already started is no longer useful, so
    // the focus moves to tomorrow as soon as nothing is left to get ready.
    final upcomingToday = _activitiesForDate(today)
        .where((activity) => activity.startMinutes() > nowMinutes);

    if (upcomingToday.isNotEmpty) {
      return true;
    }

    // Homework that is still due later today keeps today's focus alive.
    return _homeworksForDate(today).any(
      (homework) =>
          !homework.completed &&
          (homework.dueTime == null ||
              homework.dueTime!.totalMinutes > nowMinutes),
    );
  }

  DateTime get _homeNow => DateTime.now();

  bool get _showTodaySchedule {
    final homeNow = _homeNow;
    final nowMinutes = homeNow.hour * 60 + homeNow.minute;
    final today = _dayOnly(homeNow);

    return _activitiesForDate(today)
        .any((activity) => activity.endMinutes() > nowMinutes);
  }

  Future<void> _chooseActiveChild() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Bag2SchoolColors.warmPaper,
      builder: (sheetContext) =>
          ChildSwitcherSheet(initialChildId: Bag2SchoolStore.activeChildId),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.switchActiveChild(selected);
    });
  }

  Future<void> _editChildProfile() async {
    final nameController = TextEditingController(
      text: Bag2SchoolStore.childName,
    );
    final gradeController = TextEditingController(
      text: Bag2SchoolStore.childGrade,
    );

    final activeChild = Bag2SchoolStore.activeChild;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          title: const Text(
            'Child Profile',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Child photos are intentionally not collected: no camera or
                // gallery access, which keeps the app free of child images.
                _buildChildAvatar(size: 92),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gradeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, {'action': 'delete'});
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete child'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final grade = gradeController.text.trim();

                if (name.isEmpty || grade.isEmpty) return;

                Navigator.pop(dialogContext, {
                  'action': 'save',
                  'name': name,
                  'grade': grade,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      disposeControllersAfterRoute([nameController, gradeController]);
      return;
    }

    if (result['action'] == 'delete') {
      final childName = Bag2SchoolStore.childName;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (warningContext) {
          return AlertDialog(
            backgroundColor: _cream,
            title: const Text(
              'Delete child?',
              style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
            ),
            content: Text(
              'Are you sure you want to delete $childName? '
              'This child will be removed from your family. '
              'This action can\'t be undone.',
              style: const TextStyle(color: _muted, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(warningContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(warningContext, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete child'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final success = await Bag2SchoolStore.deleteActiveChild();

        if (!mounted) return;

        if (success) {
          setState(() {});
          showAppNotification(
            context,
            title: 'Child deleted',
            message: '$childName has been removed from your family.',
            icon: Icons.delete_outline_rounded,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not delete this child. Please try again.'),
            ),
          );
        }
      }
    } else {
      setState(() {
        Bag2SchoolStore.updateActiveChild(
          name: result['name'],
          grade: result['grade'],
        );
      });
    }

    // Let the dialog's TextFields detach before disposing their controllers.
    disposeControllersAfterRoute([nameController, gradeController]);
  }

  Widget _buildChildAvatar({double size = 68}) {
    final child = Bag2SchoolStore.activeChild;

    return ChildAvatar(
      avatarUrl: child.avatarUrl,
      gender: child.gender,
      size: size,
    );
  }

  /// Small cards for the other children in the family. Tapping one opens a
  /// read-only view of that child's tomorrow.
  /// Shown when Home is running on the cached family.
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD7AE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: _orangeText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline · showing the last saved data. Changes still save on '
              'this device.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: _orangeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherChildCards() {
    final others = Bag2SchoolStore.childProfiles
        .where((child) => child.id != Bag2SchoolStore.activeChildId)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    final familyName = Bag2SchoolStore.currentFamilyName?.trim() ?? '';

    return Column(
      key: _tutorialOtherChildrenKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 16, color: _muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                familyName.isEmpty
                    ? 'Other children in this family'
                    : '$familyName · other children',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: others.map(_buildOtherChildCard).toList(),
        ),
      ],
    );
  }

  Widget _buildOtherChildCard(ChildProfile child) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showChildTomorrow(child),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChildAvatar(
                avatarUrl: child.avatarUrl,
                gender: child.gender,
                size: 32,
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const Text(
                    'View tomorrow',
                    style: TextStyle(fontSize: 10.5, color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChildTomorrow(ChildProfile child) async {
    final tomorrow = _dayOnly(DateTime.now().add(const Duration(days: 1)));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${child.name} · tomorrow',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatDateLong(tomorrow),
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 400,
                ),
                child: FutureBuilder<ChildDayData>(
                  future: Bag2SchoolStore.dayDataForChild(child.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: _orange),
                        ),
                      );
                    }

                    final data =
                        snapshot.data ??
                        const ChildDayData(
                          activities: <BagActivity>[],
                          preparations: <PreparationItem>[],
                          homeworks: <HomeworkItem>[],
                        );

                    final activities =
                        data.activities
                            .where((activity) => activity.occursOn(tomorrow))
                            .toList()
                          ..sort(
                            (a, b) =>
                                a.startMinutes().compareTo(b.startMinutes()),
                          );

                    final activityIds = activities
                        .map((activity) => activity.id)
                        .toSet();

                    final preparations = data.preparations
                        .where(
                          (item) =>
                              activityIds.contains(item.activityId) ||
                              _dayOnly(item.preparationDate) == tomorrow,
                        )
                        .toList();

                    final homeworks = data.homeworks
                        .where((item) => _dayOnly(item.dueDate) == tomorrow)
                        .toList();

                    if (activities.isEmpty &&
                        preparations.isEmpty &&
                        homeworks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'Nothing saved for tomorrow yet.',
                            style: TextStyle(fontSize: 13, color: _muted),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activities.isNotEmpty) ...[
                            _daySectionLabel('Schedule'),
                            ...activities.map(_readOnlyActivityRow),
                          ],
                          if (preparations.isNotEmpty) ...[
                            _daySectionLabel('Preparation'),
                            ...preparations.map(
                              (item) => _readOnlySimpleRow(
                                icon: Icons.checklist_rounded,
                                color: _orange,
                                title: item.title,
                              ),
                            ),
                          ],
                          if (homeworks.isNotEmpty) ...[
                            _daySectionLabel('Homework'),
                            ...homeworks.map(
                              (item) => _readOnlySimpleRow(
                                icon: Icons.menu_book_rounded,
                                color: _purple,
                                title: item.task,
                                subtitle: item.subject,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'View only. Switch the active child to make changes.',
                style: TextStyle(fontSize: 11.5, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _daySectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          letterSpacing: .8,
          fontWeight: FontWeight.w900,
          color: _muted,
        ),
      ),
    );
  }

  Widget _readOnlyActivityRow(BagActivity activity) {
    final typeName = activity.type.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              _activityIcon(activity),
              color: _activityColor(activity),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  Text(
                    '${_formatTime(activity.startTime)} – '
                    '${_formatTime(activity.endTime)}'
                    '${typeName.isEmpty ? '' : ' · ${typeName[0].toUpperCase()}${typeName.substring(1)}'}',
                    style: const TextStyle(fontSize: 11.5, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlySimpleRow({
    required IconData icon,
    required Color color,
    required String title,
    String subtitle = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: _muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBagiCompanion() {
    return IgnorePointer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 58, height: 58, child: const BagiCharacter()),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _purpleSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: const Color(0xFFE0D9FF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      _bagiHomeVisibleMessage.isEmpty
                          ? '...'
                          : _bagiHomeVisibleMessage,
                      key: ValueKey(_bagiHomeVisibleMessage),
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4D445B),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: 10,
                  child: CustomPaint(
                    size: const Size(10, 16),
                    painter: BagiHomeBubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowSection(DateTime tomorrow) {
    final homeNow = _homeNow;
    final nowMinutes = homeNow.hour * 60 + homeNow.minute;
    final today = _dayOnly(homeNow);
    final isToday = _dayOnly(tomorrow) == today;

    final activities = _activitiesForDate(tomorrow)
        .where((activity) => !isToday || activity.endMinutes() > nowMinutes)
        .toList();

    return Container(
      padding: activities.isEmpty
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Bag2SchoolRadii.panel),
        boxShadow: activities.isEmpty
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: activities.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nothing scheduled for tomorrow yet.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  _homeScheduleItem(activities[i]),
                  if (i != activities.length - 1) const Divider(height: 18),
                ],
              ],
            ),
    );
  }

  Widget _homeScheduleItem(BagActivity activity) {
    final color = _activityColor(activity);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _activityBackground(activity),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_activityIcon(activity), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatTime(activity.startTime)} – ${_formatTime(activity.endTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (activity.type == ActivityType.exam)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'EXAM',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
                color: _teal,
              ),
            ),
          ),
      ],
    );
  }

  /// Progress ring for the readiness card. The percentage is laid out with a
  /// FittedBox so a large text scale can never overflow the circle.
  Widget _buildReadinessRing({
    required double progress,
    required Color accent,
    required Color trackColor,
  }) {
    // Animate from empty to the current value so the ring never jumps.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final percent = (value * 100).round();

        return SizedBox.square(
          dimension: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 88,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadinessStatus({required int left, required bool isToday}) {
    final allSet = left <= 0;
    final background = allSet
        ? const Color(0xFFE3F1DD)
        : (isToday ? const Color(0xFFFFE8D5) : const Color(0xFFF0EDFF));
    final foreground = allSet
        ? const Color(0xFF3F7A4C)
        : (isToday ? _orangeText : _purpleText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allSet ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            allSet ? 'All set' : '$left left',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// One readiness checklist row. Tapping it toggles completion, exactly like
  /// the previous inline rows.
  Widget _buildReadinessRow({
    required String title,
    required bool checked,
    required Color accent,
    required VoidCallback onTap,
    String? subtitle,
    String? tag,
    Color? tagBackground,
    Color? tagColor,
  }) {
    const doneGreen = Color(0xFF55A56B);
    final trimmedSubtitle = subtitle?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // A ticked row turns light green, so progress is visible at a glance.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: checked
              ? const Color(0xFFE4F2DC)
              : Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: checked ? doneGreen : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: checked
                            ? doneGreen
                            : accent.withValues(alpha: .55),
                        width: 2,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: checked ? 1 : 0.5,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: checked ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: _muted,
                          ),
                        ),
                        if (trimmedSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            trimmedSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tagBackground ?? const Color(0xFFFFE8D5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 8.5,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900,
                          color: tagColor ?? _orangeText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationSummary(DateTime targetDate) {
    final homeNow = _homeNow;
    final today = _dayOnly(homeNow);
    final isToday = _dayOnly(targetDate) == today;
    final nowMinutes = homeNow.hour * 60 + homeNow.minute;

    final allPreparations = _preparationsForDate(targetDate);

    final preparations = isToday
        ? allPreparations.where((item) {
            final activity = _activitiesForDate(targetDate)
                .where((activity) => activity.id == item.activityId)
                .cast<BagActivity?>()
                .firstWhere((activity) => activity != null, orElse: () => null);

            // Only items whose activity has not started yet still need work.
            return activity != null && activity.startMinutes() > nowMinutes;
          }).toList()
        : allPreparations;

    final targetHomeworks = _homeworksForDate(targetDate);
    final totalItems = preparations.length + targetHomeworks.length;
    final progress = _readinessProgress(
      targetDate,
      preparations,
      targetHomeworks,
    );
    final done = (progress * totalItems).round();
    final isTodayFocus = _showTodayPreparation;
    final title = isToday ? 'GET READY FOR TODAY' : 'GET READY FOR TOMORROW';
    final emptyText = isTodayFocus
        ? 'No preparation or homework for today.'
        : 'No preparation or homework for tomorrow yet.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFFFE9D6) : const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isToday ? _orangeText : _purpleText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDateLong(targetDate),
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (totalItems == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            // The small panel stays white; each ticked row turns green below.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  _buildReadinessRing(
                    progress: progress,
                    accent: isToday ? _orange : _purple,
                    trackColor: isToday
                        ? const Color(0xFFFFE0C7)
                        : const Color(0xFFE3DCFF),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$done of $totalItems ready',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildReadinessStatus(
                          left: totalItems - done,
                          isToday: isToday,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: isToday
                                ? const Color(0xFFFFE0C7)
                                : const Color(0xFFE3DCFF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isToday ? _orange : _purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Real Preparation items.
            ...preparations.map((item) {
              BagActivity? related;
              for (final activity in _activitiesForDate(targetDate)) {
                if (activity.id == item.activityId) {
                  related = activity;
                  break;
                }
              }

              return _buildReadinessRow(
                title: item.title,
                subtitle: related?.title,
                checked: _isPreparationChecked(item, targetDate),
                accent: _orange,
                onTap: () => _toggleHomePreparation(item, targetDate),
              );
            }),

            // Homework uses the same readiness checklist, but its completion
            // is linked to the Homework page so the state stays in sync.
            ...targetHomeworks.map((homework) {
              final checked = _isHomeHomeworkChecked(homework);

              return _buildReadinessRow(
                title: homework.task,
                subtitle: homework.subject,
                tag: 'HOMEWORK',
                checked: checked,
                accent: _purple,
                tagBackground: const Color(0xFFE8E1FF),
                tagColor: _purpleText,
                onTap: () => _toggleHomeHomework(homework),
              );
            }),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PreparationPage()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Check Preparation'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<HomeworkItem> _homeworksForHome() {
    final now = _dayOnly(DateTime.now());
    return Bag2SchoolStore.homeworks
        .where((homework) => !homework.completed)
        .toList()
      ..sort((a, b) {
        final aOverdue = _dayOnly(a.dueDate).isBefore(now);
        final bOverdue = _dayOnly(b.dueDate).isBefore(now);
        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  List<HomeworkItem> _homeworksForDate(DateTime date) {
    final clean = _dayOnly(date);
    return Bag2SchoolStore.homeworks
        .where((homework) => _dayOnly(homework.dueDate) == clean)
        .toList()
      ..sort((a, b) {
        final aTime = a.dueTime?.totalMinutes ?? 1440;
        final bTime = b.dueTime?.totalMinutes ?? 1440;
        return aTime.compareTo(bTime);
      });
  }

  Widget _buildHomeworkSummary() {
    final homework = _homeworksForHome();

    return Container(
      key: _tutorialHomeHomeworkKey,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _purpleSoft,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0D9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: _purple, size: 24),
              SizedBox(width: 10),
              Text(
                'HOMEWORK TO DO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            homework.isEmpty
                ? 'Everything is caught up. Great job! 🎉'
                : '${homework.length} homework item${homework.length == 1 ? '' : 's'} still need attention.',
            style: const TextStyle(
              fontSize: 12.5,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (homework.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...homework.take(3).map((item) {
              final overdue = _dayOnly(item.dueDate)
                  .isBefore(_dayOnly(DateTime.now()));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.book_outlined,
                        size: 20,
                        color: overdue ? const Color(0xFFD94B4B) : _purple,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.task,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              overdue
                                  ? 'Overdue · ${_formatDateLong(item.dueDate)}'
                                  : 'Due · ${_formatDateLong(item.dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: overdue
                                    ? const Color(0xFFD94B4B)
                                    : _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeworkPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _purpleText,
                side: const BorderSide(color: Color(0xFFCFC4F7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Open Homework'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void _openNotificationTarget(LocalFamilyNotification notification) {
    Bag2SchoolStore.switchActiveChild(notification.childId);
    switch (notification.entityType) {
      case 'schedule':
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        break;
      case 'homework':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeworkPage()),
        );
        break;
      case 'preparation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreparationPage(
              completed: const <bool>[false, false, false],
              onChanged: (_, __) {},
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyActivityPage()),
        );
    }
  }

  void _openAccessResponseTarget(LocalAccessRequest request) {
    Bag2SchoolStore.switchActiveChild(request.childId);
    switch (request.feature) {
      case LocalPermissionFeature.schedule:
      case LocalPermissionFeature.exam:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        break;
      case LocalPermissionFeature.homework:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeworkPage()),
        );
        break;
      case LocalPermissionFeature.preparation:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreparationPage(
              completed: const <bool>[false, false, false],
              onChanged: (_, __) {},
            ),
          ),
        );
        break;
    }
  }

  Future<void> _showNotifications() async {
    Bag2SchoolStore.pruneNotificationInbox();

    Bag2SchoolStore.markCurrentNotificationsRead();
    if (mounted) setState(() {});

    final currentRole = Bag2SchoolStore.familyMemberForCurrentAccount()?.role;

    final isOwner = currentRole == FamilyMemberRole.owner;
    final activityNotifications =
        Bag2SchoolStore.notificationsForCurrentMember();
    final recentNotifications = activityNotifications.take(5).toList();
    List<LocalAccessRequest> pendingRequests() => Bag2SchoolStore.accessRequests
        .where((request) => request.status == AccessRequestStatus.pending)
        .toList();

    if (!isOwner) {
      final responses = Bag2SchoolStore.responseNotificationsForCurrentMember();

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Family Updates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access responses and family updates',
                style: TextStyle(fontSize: 11.5, color: _muted),
              ),
              const SizedBox(height: 14),
              if (responses.isEmpty && activityNotifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 42,
                        color: _orange,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No new updates.',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              if (activityNotifications.isNotEmpty)
                ...recentNotifications.map(
                  (notification) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _orange,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openNotificationTarget(notification),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text('View'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  foregroundColor: _orangeText,
                                  side: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (activityNotifications.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyActivityPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('View all notifications'),
                  ),
                ),
              if (responses.isNotEmpty)
                ...responses.map((request) {
                  final child = Bag2SchoolStore.childProfiles
                      .where((entry) => entry.id == request.childId)
                      .cast<ChildProfile?>()
                      .firstWhere((entry) => entry != null, orElse: () => null);
                  final feature = LocalAuthorization.featureLabel(
                    request.feature,
                  );
                  final approved =
                      request.status == AccessRequestStatus.approved;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          approved
                              ? Icons.verified_rounded
                              : Icons.block_rounded,
                          color: approved
                              ? const Color(0xFF55A56B)
                              : const Color(0xFFB55252),
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                approved
                                    ? (request.requestEdit
                                          ? 'Edit access granted: $feature for ${child?.name ?? 'this child'}.'
                                          : 'Access granted: $feature for ${child?.name ?? 'this child'}.')
                                    : (request.requestEdit
                                          ? 'Edit access request declined: $feature for ${child?.name ?? 'this child'}.'
                                          : 'Access request declined: $feature for ${child?.name ?? 'this child'}.'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openAccessResponseTarget(request),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text('View'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  foregroundColor: _orangeText,
                                  side: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      );
      return;
    }

    if (pendingRequests().isEmpty && activityNotifications.isEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: _orange,
                ),
                SizedBox(height: 8),
                Text(
                  'Family Updates',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'No new family updates or access requests.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final pending = pendingRequests();
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                const Text(
                  'Family Updates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Access requests from family members',
                  style: TextStyle(fontSize: 11.5, color: _muted),
                ),
                const SizedBox(height: 14),
                if (activityNotifications.isNotEmpty)
                  ...recentNotifications.map(
                    (notification) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: _orange,
                            size: 25,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notification.message,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: _muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _openNotificationTarget(notification),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('View'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: _orangeText,
                                    side: const BorderSide(
                                      color: Color(0xFFFFC18F),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (activityNotifications.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FamilyActivityPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('View all notifications'),
                    ),
                  ),
                ...pending.map((request) {
                  final member = Bag2SchoolStore.familyMembers
                      .where((entry) => entry.id == request.requesterMemberId)
                      .cast<FamilyMember?>()
                      .firstWhere((entry) => entry != null, orElse: () => null);
                  final child = Bag2SchoolStore.childProfiles
                      .where((entry) => entry.id == request.childId)
                      .cast<ChildProfile?>()
                      .firstWhere((entry) => entry != null, orElse: () => null);
                  final memberName = member?.displayName ?? 'Family member';
                  final childName = child?.name ?? 'Child';
                  final feature = LocalAuthorization.featureLabel(
                    request.feature,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$memberName requests access',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$feature · $childName',
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final index = Bag2SchoolStore.accessRequests
                                      .indexWhere(
                                        (entry) => entry.id == request.id,
                                      );
                                  if (index >= 0) {
                                    Bag2SchoolStore.accessRequests[index] =
                                        request.copyWith(
                                          status: AccessRequestStatus.denied,
                                        );
                                  }
                                  setSheetState(() {});
                                  setState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB55252),
                                  side: const BorderSide(
                                    color: Color(0xFFE6B7B7),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final memberId = request.requesterMemberId;
                                  final childId = request.childId;
                                  final existing =
                                      Bag2SchoolStore.accessGrantFor(
                                        childId,
                                        memberId,
                                      );
                                  final updated =
                                      existing ??
                                      FamilyAccessGrant(
                                        memberId: memberId,
                                        childId: childId,
                                      );
                                  final granted = switch (request.feature) {
                                    LocalPermissionFeature.schedule =>
                                      updated.copyWith(
                                        viewSchedule: true,
                                        editSchedule:
                                            request.requestEdit ||
                                            updated.editSchedule,
                                      ),
                                    LocalPermissionFeature.homework =>
                                      updated.copyWith(
                                        viewHomework: true,
                                        editHomework:
                                            request.requestEdit ||
                                            updated.editHomework,
                                      ),
                                    LocalPermissionFeature.preparation =>
                                      updated.copyWith(
                                        viewPreparation: true,
                                        editPreparation:
                                            request.requestEdit ||
                                            updated.editPreparation,
                                      ),
                                    LocalPermissionFeature.exam =>
                                      updated.copyWith(
                                        viewExam: true,
                                        editExam:
                                            request.requestEdit ||
                                            updated.editExam,
                                      ),
                                  };

                                  Bag2SchoolStore.saveAccessGrant(granted);

                                  final index = Bag2SchoolStore.accessRequests
                                      .indexWhere(
                                        (entry) => entry.id == request.id,
                                      );
                                  if (index >= 0) {
                                    Bag2SchoolStore.accessRequests[index] =
                                        request.copyWith(
                                          status: AccessRequestStatus.approved,
                                        );
                                  }
                                  setSheetState(() {});
                                  setState(() {});
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: _ink,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final scheduleDate = _showTodaySchedule ? today : tomorrow;

    final showTodayPreparation = _showTodayPreparation;
    final showTomorrowPreparation =
        _preparationsForDate(tomorrow).isNotEmpty ||
        _homeworksForDate(tomorrow).isNotEmpty;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Bag2SchoolSpacing.large,
            Bag2SchoolSpacing.medium,
            Bag2SchoolSpacing.large,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Bag2SchoolLogo(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _showNotifications,
                            icon: const Icon(
                              Icons.notifications_outlined,
                              size: 30,
                              color: Color(0xFF40352F),
                            ),
                          ),
                          if (Bag2SchoolStore.pendingAccessRequestCount > 0 ||
                              Bag2SchoolStore.currentMemberNotificationCount >
                                  0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 21,
                                height: 21,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${Bag2SchoolStore.pendingAccessRequestCount + Bag2SchoolStore.currentMemberNotificationCount}',
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Child profile — editing is available only from Settings.
                  if (Bag2SchoolStore.isOfflineData) ...[
                    _buildOfflineBanner(),
                    const SizedBox(height: 12),
                  ],

                  Container(
                    key: _tutorialHomeProfileKey,
                    padding: const EdgeInsets.all(Bag2SchoolSpacing.medium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Bag2SchoolRadii.card),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .04),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildChildAvatar(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Bag2SchoolStore.childName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                Bag2SchoolStore.childGrade,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.family_restroom_rounded,
                                    size: 15,
                                    color: _muted,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      (Bag2SchoolStore.currentFamilyName
                                                      ?.trim() ??
                                                  '')
                                              .isNotEmpty
                                          ? Bag2SchoolStore.currentFamilyName!
                                                .trim()
                                          : 'No family yet',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              TextButton.icon(
                                onPressed: _chooseActiveChild,
                                icon: const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                ),
                                label: const Text('Switch child'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _orangeText,
                                  minimumSize: const Size(0, 48),
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bagi now lives between child profile and Tomorrow.
                  _buildHomeBagiCompanion(),

                  const SizedBox(height: 22),

                  Text(
                    _showTodaySchedule ? 'TODAY' : 'TOMORROW',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _orangeText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateLong(scheduleDate),
                    style: const TextStyle(
                      fontSize: 15.5,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _tutorialHomeTomorrowKey,
                    child: _buildTomorrowSection(scheduleDate),
                  ),

                  const SizedBox(height: 22),
                  if (showTodayPreparation) ...[
                    _buildPreparationSummary(today),
                    const SizedBox(height: 20),
                  ],

                  if (showTomorrowPreparation) ...[
                    _buildPreparationSummary(tomorrow),
                  ],

                  const SizedBox(height: 20),
                  _buildHomeworkSummary(),

                  if (Bag2SchoolStore.childProfiles.length > 1) ...[
                    const SizedBox(height: 20),
                    _buildOtherChildCards(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: _homeTutorialNavigationKey,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchedulePage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreparationPage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeworkPage()),
            );
            return;
          }

          if (index == 4) {
            if (_ownerTutorialSettingsTapPending) {
              BagiTutorialTargetActions.activate('owner-open-settings');
              _ownerTutorialSettingsTapPending = false;
              _ownerTutorialSettingsRoute = Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(ownerSetupTutorial: true),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          setState(() => selectedIndex = index);
        },
        indicatorColor: const Color(0xFFFFE2CF),
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

class Bag2SchoolLogo extends StatelessWidget {
  const Bag2SchoolLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: 'Bag2',
            style: TextStyle(color: Bag2SchoolColors.orangeText),
          ),
          TextSpan(
            text: 'School',
            style: TextStyle(color: Color(0xFF29231F)),
          ),
        ],
      ),
    );
  }
}
