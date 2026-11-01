import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/activity_models.dart';
import '../../models/family_models.dart';
import '../../services/bagi_greeting_service.dart';
import '../../services/bagi_message.dart';
import '../../services/preparation_defaults.dart';
import '../../utils/controllers.dart';
import '../../utils/focus.dart';
import '../../widgets/bagi_character.dart';
import '../../widgets/bagi_tutorial_overlay.dart';
import '../../widgets/bubble_tail_painters.dart';
import '../homework/homework_page.dart';
import '../schedule/schedule_page.dart';
import '../settings/settings_page.dart';

// Preparation screen: today, tomorrow and upcoming readiness.
// Extracted from lib/main.dart (step 5b).

class PreparationPage extends StatefulWidget {
  // Kept optional for compatibility with the earlier navigation code.
  // V3 reads the real shared preparation store instead of demo checklist data.
  final List<bool> completed;
  final void Function(int index, bool value)? onChanged;
  final bool tutorial;
  final int tutorialStep;

  const PreparationPage({
    super.key,
    this.completed = const <bool>[],
    this.onChanged,
    this.tutorial = false,
    this.tutorialStep = 12,
  });

  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  final GlobalKey _tutorialPreparationTodayKey = GlobalKey();
  Timer? _bagiTimer;
  final Random _random = Random();
  final Set<String> _expandedPreparationGroups = <String>{};
  bool _showAllUpcoming = false;
  String _bagiMessage = '';
  String? _lastMessage;
  int _bagiMessageVersion = 0;

  String _currentBagiGreeting() {
    return BagiGreetingService.current(
      childName: Bag2SchoolStore.childName,
      preferredTitle: bagiAccountAddressName(),
    );
  }

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDayData time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  BagActivity? _activityFor(PreparationItem item) {
    for (final activity in Bag2SchoolStore.activities) {
      if (activity.id == item.activityId) return activity;
    }
    return null;
  }

  HomeworkItem? _homeworkForPreparationId(String activityId) {
    if (!activityId.startsWith('homework:')) return null;
    final id = activityId.substring('homework:'.length);
    for (final homework in Bag2SchoolStore.homeworks) {
      if (homework.id == id) return homework;
    }
    return null;
  }

  HomeworkItem? _homeworkForGroup(_PreparationGroup group) {
    for (final item in group.items) {
      final homework = _homeworkForPreparationItem(item);
      if (homework != null) return homework;
    }
    return null;
  }

  String _preparationGroupTitle(_PreparationGroup group) {
    return group.activity?.title ?? 'Preparation';
  }

  String _personalizeBagi(String message) {
    return personalizeBagiMessage(message);
  }

  String _categoryLabel(BagActivity? activity) {
    if (activity == null) return 'Activity';
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

  IconData _activityIcon(BagActivity? activity) {
    if (activity == null) return Icons.event_note_outlined;
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

  Color _activityTint(BagActivity? activity) {
    if (activity == null) return const Color(0xFF7D6D64);
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFF4C8FD9);
      case ActivityType.lesson:
        return const Color(0xFF7661D8);
      case ActivityType.extracurricular:
        return const Color(0xFFFF7A21);
      case ActivityType.exam:
        return const Color(0xFF2A9D8F);
      case ActivityType.event:
        return const Color(0xFF4C956C);
    }
  }

  List<PreparationItem> _itemsForDate(DateTime date) {
    final clean = _dayOnly(date);
    return Bag2SchoolStore.preparations
        .where((item) => item.occursOn(clean))
        .toList();
  }

  List<DateTime> _preparationDates() {
    final dates = Bag2SchoolStore.preparations
        .map((item) => _dayOnly(item.preparationDate))
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  int _done(List<PreparationItem> items) =>
      items.where(_isOccurrenceChecked).length;

  double _progress(List<PreparationItem> items) {
    if (items.isEmpty) return 0;
    return _done(items) / items.length;
  }

  String _progressText(List<PreparationItem> items) {
    return '${_done(items)} of ${items.length} ready';
  }

  List<_PreparationGroup> _groupsForTodayAndFuture() {
    final today = _dayOnly(DateTime.now());
    final byActivity = <String, _PreparationGroup>{};

    void addOccurrence(
      DateTime date,
      BagActivity? activity,
      String activityId,
    ) {
      if (date.isBefore(today)) return;
      if (activity != null &&
          Bag2SchoolStore.isOccurrenceCancelled(date, activity.id))
        return;

      final items = Bag2SchoolStore.preparationsForOccurrence(date, activityId);

      // An explicit empty override means this occurrence was intentionally
      // cleared. Do not resurrect it from the recurring template.
      if (items.isEmpty) return;

      final key = '${date.toIso8601String()}|$activityId';
      final group = byActivity.putIfAbsent(
        key,
        () => _PreparationGroup(
          date: date,
          activityId: activityId,
          activity: activity,
        ),
      );

      group.items
        ..clear()
        ..addAll(items);
    }

    // First build every occurrence of every scheduled activity for the next
    // 30 days. This is what makes Mon-Fri School preparation appear on
    // Today, Tomorrow and Upcoming.
    for (final activity in Bag2SchoolStore.activities) {
      for (var offset = 0; offset <= 30; offset++) {
        final date = today.add(Duration(days: offset));
        if (activity.occursOn(date)) {
          addOccurrence(date, activity, activity.id);
        }
      }
    }

    // Also keep standalone preparations / explicitly dated preparations that
    // do not currently have a matching activity occurrence.
    for (final item in Bag2SchoolStore.preparations) {
      final date = _dayOnly(item.preparationDate);
      if (date.isBefore(today)) continue;
      final activity = _activityFor(item);
      if (activity == null) {
        final key = '${date.toIso8601String()}|${item.activityId}';
        final group = byActivity.putIfAbsent(
          key,
          () => _PreparationGroup(
            date: date,
            activityId: item.activityId,
            activity: null,
          ),
        );
        if (!group.items.any((existing) => existing.id == item.id)) {
          group.items.add(item);
        }
      }
    }

    final groups = byActivity.values.toList();
    groups.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;

      final aMinutes = a.activity?.startMinutes() ?? 1440;
      final bMinutes = b.activity?.startMinutes() ?? 1440;
      return aMinutes.compareTo(bMinutes);
    });
    return groups;
  }

  // History is hidden from the Preparation screen; kept for a future design.
  List<_PreparationGroup> _historyGroups() {
    final today = _dayOnly(DateTime.now());
    final byActivity = <String, _PreparationGroup>{};

    for (final item in Bag2SchoolStore.preparations) {
      final date = _dayOnly(item.preparationDate);
      if (!date.isBefore(today)) continue;

      final activity = _activityFor(item);
      final items = activity == null
          ? <PreparationItem>[item]
          : Bag2SchoolStore.preparationsForOccurrence(date, activity.id);

      if (items.isEmpty) continue;

      final key = '${date.toIso8601String()}|${item.activityId}';
      final group = byActivity.putIfAbsent(
        key,
        () => _PreparationGroup(
          date: date,
          activityId: item.activityId,
          activity: activity,
        ),
      );
      group.items
        ..clear()
        ..addAll(items);
    }

    final groups = byActivity.values.toList();
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  List<String> _bagiThoughts() {
    final today = _dayOnly(DateTime.now());
    final groups = _groupsForTodayAndFuture();

    final todayGroups = groups.where((group) => group.date == today).toList();

    final messages = <String>[];

    if (todayGroups.isEmpty) {
      messages.add(
        "${_currentBagiGreeting()} 😊 "
        "Looks like we're all set for today. "
        "Nothing needs preparing right now. ☀️",
      );
    } else {
      final total = todayGroups.expand((group) => group.items).toList();

      final ready = _done(total);

      if (ready == total.length) {
        messages.add(
          "${_currentBagiGreeting()} 🎉 "
          "We're all set for today. "
          "You can relax — everything is ready!",
        );
      } else {
        messages.add(
          "${_currentBagiGreeting()} 😊 "
          "We have ${todayGroups.length} "
          "${todayGroups.length == 1 ? 'thing' : 'things'} today. "
          "$ready of ${total.length} little preparations are ready.",
        );

        final needsAttention = todayGroups
            .where((group) => _progress(group.items) < 1)
            .toList();

        if (needsAttention.isNotEmpty) {
          final target = needsAttention[_random.nextInt(needsAttention.length)];

          final remaining = target.items.length - _done(target.items);

          messages.add(
            _personalizeBagi(
              "${target.activity?.title ?? 'Today'} still has "
              "$remaining "
              "${remaining == 1 ? 'little thing' : 'little things'} "
              "to get ready. No rush, {parent}! 🌿",
            ),
          );
        }
      }
    }

    final tomorrow = today.add(const Duration(days: 1));

    final tomorrowGroups = groups
        .where((group) => group.date == tomorrow)
        .toList();

    if (tomorrowGroups.isNotEmpty) {
      final group = tomorrowGroups.first;

      messages.add(
        _personalizeBagi(
          "Psst, {parent}! "
          "${group.activity?.title ?? 'Something'} is tomorrow. "
          "We can get a little head start today. 😊",
        ),
      );
    }

    return messages;
  }

  void _startBagi() {
    _bagiTimer?.cancel();
    _showNextBagi();
    _bagiTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _showNextBagi(),
    );
  }

  void _showNextBagi() {
    if (!mounted) return;

    final messages = _bagiThoughts();
    if (messages.isEmpty) return;

    final candidates = messages.length > 1
        ? messages.where((message) => message != _lastMessage).toList()
        : messages;

    final message = candidates[_random.nextInt(candidates.length)];

    _lastMessage = message;

    final version = ++_bagiMessageVersion;
    final words = message.split(' ');

    // Show the first word immediately.
    setState(() {
      _bagiMessage = words.isEmpty ? '' : words.first;
    });

    // Reveal the remaining words one by one.
    for (var i = 2; i <= words.length; i++) {
      Future.delayed(Duration(milliseconds: 90 * (i - 1)), () {
        if (!mounted || version != _bagiMessageVersion) return;

        setState(() {
          _bagiMessage = words.take(i).join(' ');
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _startBagi();
      if (widget.tutorial) unawaited(_runPreparationTutorial());
    });
  }

  Future<void> _runPreparationTutorial() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final targetContext = _tutorialPreparationTodayKey.currentContext;
    if (targetContext != null) await Scrollable.ensureVisible(targetContext);
    if (!mounted) return;
    final action = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _tutorialPreparationTodayKey,
      stepLabel: 'Step ${widget.tutorialStep} of ${widget.tutorialStep + 5}',
      title: 'Preparation',
      message: 'Check the items your child needs for school and mark each one ready as you pack it.',
    );
    if (mounted) Navigator.of(context).pop(action != BagiTutorialAction.skip);
  }

  @override
  void dispose() {
    _bagiTimer?.cancel();
    super.dispose();
  }

  String _occurrenceKey(PreparationItem item) {
    return '${_dayOnly(item.preparationDate).toIso8601String()}|${item.id}';
  }

  bool _isOccurrenceChecked(PreparationItem item) {
    final linkedHomework = _homeworkForPreparationItem(item);
    if (linkedHomework != null) {
      final key =
          '${_dayOnly(item.preparationDate).toIso8601String()}|${linkedHomework.id}';
      return Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;
    }

    final date = _dayOnly(item.preparationDate);
    final overrideKey = Bag2SchoolStore.preparationOccurrenceKey(
      date,
      item.activityId,
    );

    final overrideItems =
        Bag2SchoolStore.preparationOccurrenceOverrides[overrideKey];
    if (overrideItems != null) {
      final overrideItem = overrideItems
          .where((entry) => entry.id == item.id)
          .cast<PreparationItem?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      if (overrideItem != null) return overrideItem.completed;
    }

    return Bag2SchoolStore
            .preparationOccurrenceCompletion['${date.toIso8601String()}|${item.id}'] ??
        item.completed;
  }

  Future<void> _editPreparationGroup(_PreparationGroup group) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'edit',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    // Homework is displayed in Preparation as a linked reference only.
    // It must never enter the preparation editor or become removable from
    // this dialog. Only real preparation items are editable here.
    final editableItems = group.items
        .where((item) => !_isHomeworkPreparation(item))
        .toList();
    final homeworkItems = group.items
        .where((item) => _isHomeworkPreparation(item))
        .toList();

    final controllers = <TextEditingController>[
      for (final item in editableItems) TextEditingController(text: item.title),
    ];
    final ids = <String?>[for (final item in editableItems) item.id];
    final originalItems = <PreparationItem>[...editableItems];
    var dialogClosed = false;

    void saveChanges(StateSetter setDialogState) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final updated = <PreparationItem>[];

      for (var i = 0; i < controllers.length; i++) {
        final title = controllers[i].text.trim();
        if (title.isEmpty) continue;

        final existingId = ids[i];
        PreparationItem? source;

        if (existingId != null) {
          for (final item in originalItems) {
            if (item.id == existingId) {
              source = item;
              break;
            }
          }
        }

        source ??= PreparationItem(
          id: 'preparation-occurrence-$stamp-$i',
          activityId: group.activityId,
          title: title,
          preparationDate: group.date,
        );

        if (existingId == null) {
          // Prevent a second Save from creating the same new item again.
          ids[i] = source.id;
        }

        updated.add(source.copyWith(title: title, preparationDate: group.date));
      }

      final key = Bag2SchoolStore.preparationOccurrenceKey(
        group.date,
        group.activityId,
      );

      // Keep linked homework in the occurrence untouched. Homework is not
      // part of the preparation editor, but it must remain visible in the
      // Preparation page after the edit is saved.
      final occurrenceItems = <PreparationItem>[...updated, ...homeworkItems];

      // The occurrence now owns its own list. This is the critical V4-style
      // boundary: editing Aug 17 cannot mutate Aug 18/Aug 19 templates.
      Bag2SchoolStore.preparationOccurrenceOverrides[key] = occurrenceItems;

      Bag2SchoolStore.recordFamilyActivity(
        feature: LocalPermissionFeature.preparation,
        action: 'Edited',
        title: 'Preparation updated',
        message:
            '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
            'updated preparation for ${Bag2SchoolStore.activeChild.name} on '
            '${group.date.day}/${group.date.month}/${group.date.year}.',
        childId: Bag2SchoolStore.activeChildId,
        entityId: group.activityId,
      );
      Bag2SchoolStore.persistSchoolDataSoon();

      // Completion belongs to the edited occurrence. Preserve completion
      // for existing items while resetting brand-new items to false.
      for (final item in updated) {
        final occurrenceItemKey =
            '${_dayOnly(group.date).toIso8601String()}|${item.id}';
        if (Bag2SchoolStore.preparationOccurrenceCompletion.containsKey(
          occurrenceItemKey,
        )) {
          continue;
        }
        final original = originalItems.where((entry) => entry.id == item.id);
        if (original.isNotEmpty && original.first.completed) {
          Bag2SchoolStore.preparationOccurrenceCompletion[occurrenceItemKey] =
              true;
        }
      }

      // Old hide flags must never resurrect/override the new occurrence list.
      for (final item in originalItems) {
        Bag2SchoolStore.preparationOccurrenceHidden.remove(
          '${_dayOnly(group.date).toIso8601String()}|${item.id}',
        );
      }

      setDialogState(() {});
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: Row(
                children: [
                  const SizedBox(width: 46, height: 46, child: BagiCharacter()),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Let’s get things ready ✨',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit, remove, or add anything your child needs.',
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < controllers.length; i++)
                        Padding(
                          key: ValueKey(ids[i] ?? 'new-preparation-$i'),
                          padding: const EdgeInsets.only(bottom: 9),
                          child: TextField(
                            controller: controllers[i],
                            onChanged: (_) => setDialogState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Preparation ${i + 1}',
                              suffixIcon: IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  final controller = controllers[i];
                                  await settleDialogFocus();
                                  if (!dialogContext.mounted) return;

                                  setDialogState(() {
                                    if (controllers.length == 1) {
                                      controller.clear();
                                      ids[i] = null;
                                      return;
                                    }
                                    controllers.removeAt(i);
                                    ids.removeAt(i);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (!dialogClosed)
                                            controller.dispose();
                                        });
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await settleDialogFocus();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              controllers.add(TextEditingController());
                              ids.add(null);
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add preparation'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nothing changes until you tap Save.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8A7E76),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await settleDialogFocus();
                    if (!dialogContext.mounted) return;
                    dialogClosed = true;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                Builder(
                  builder: (context) {
                    final hasAnyPreparationText = controllers.any(
                      (controller) => controller.text.trim().isNotEmpty,
                    );
                    return FilledButton.icon(
                      onPressed: hasAnyPreparationText
                          ? () async {
                              // One way to finish: apply the draft and close.
                              saveChanges(setDialogState);
                              await settleDialogFocus();
                              if (!dialogContext.mounted) return;
                              dialogClosed = true;
                              Navigator.of(dialogContext).pop();
                            }
                          : null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    disposeControllersAfterRoute(controllers);

    if (mounted) setState(() {});
  }

  Future<void> _deletePreparationItem(PreparationItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    final homework = _homeworkForPreparationItem(item);
    if (homework != null) {
      await _deleteHomeworkFromPreparation(homework);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this preparation?'),
        content: Text('Remove “${item.title}” from this preparation list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD94B4B),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final date = _dayOnly(item.preparationDate);
    final key = Bag2SchoolStore.preparationOccurrenceKey(date, item.activityId);

    setState(() {
      final override = Bag2SchoolStore.preparationOccurrenceOverrides[key];

      if (override != null) {
        final updated = override.where((p) => p.id != item.id).toList();
        Bag2SchoolStore.preparationOccurrenceOverrides[key] = updated;
      } else {
        Bag2SchoolStore.preparations.removeWhere((p) => p.id == item.id);
        Bag2SchoolStore.preparationOccurrenceHidden.add(
          '${date.toIso8601String()}|${item.id}',
        );
      }

      Bag2SchoolStore.preparationOccurrenceCompletion.remove(
        '${date.toIso8601String()}|${item.id}',
      );
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation deleted',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'deleted a preparation item for ${Bag2SchoolStore.activeChild.name}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: item.id,
    );
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  Future<void> _deleteHomeworkFromPreparation(HomeworkItem homework) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: 'preparation',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this homework?'),
        content: Text(
          'This will also remove “${homework.task}” from the Homework page and its calendar dot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD94B4B),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Homework'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      Bag2SchoolStore.homeworks.removeWhere((h) => h.id == homework.id);
      final prepId = 'prep-${homework.id}';
      Bag2SchoolStore.preparations.removeWhere((p) => p.id == prepId);
      for (final entry
          in Bag2SchoolStore.preparationOccurrenceOverrides.entries.toList()) {
        Bag2SchoolStore.preparationOccurrenceOverrides[entry.key] = entry.value
            .where((p) => p.id != prepId)
            .toList();
      }
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation homework removed',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'removed ${homework.task} from preparation for ${Bag2SchoolStore.activeChild.name}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: homework.id,
    );
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  Future<void> _deletePreparationGroup(_PreparationGroup group) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Clear this preparation? 🧺',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove all preparation items for '
          '${group.activity?.title ?? 'this activity'} on ${_formatDate(group.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;

    final key = Bag2SchoolStore.preparationOccurrenceKey(
      group.date,
      group.activityId,
    );

    setState(() {
      // Empty override = intentionally empty occurrence. Tomorrow and
      // Upcoming keep their own template/override untouched.
      Bag2SchoolStore.preparationOccurrenceOverrides[key] = <PreparationItem>[];

      for (final item in group.items) {
        final occurrenceItemKey =
            '${_dayOnly(group.date).toIso8601String()}|${item.id}';
        Bag2SchoolStore.preparationOccurrenceHidden.add(occurrenceItemKey);
        Bag2SchoolStore.preparationOccurrenceCompletion.remove(
          occurrenceItemKey,
        );
      }
    });
    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation cleared',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} cleared preparation for ${_formatDate(group.date)}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: group.activityId,
    );
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  void _toggleItem(PreparationItem item, bool value) {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'change',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    final homework = _homeworkForPreparationItem(item);
    final activity = _activityFor(item);
    final activityTitle = activity?.title ?? 'Preparation';
    final date = _dayOnly(item.preparationDate);

    setState(() {
      if (homework != null) {
        final key = '${date.toIso8601String()}|${homework.id}';
        Bag2SchoolStore.homeworkPreparationCompletion[key] = value;
        Bag2SchoolStore.recordFamilyActivity(
          feature: LocalPermissionFeature.preparation,
          action: 'Edited',
          title: 'Preparation checklist updated',
          message:
              '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
              '${value ? 'checked' : 'unchecked'} ${homework.task} '
              'for $activityTitle.',
          childId: Bag2SchoolStore.activeChildId,
          entityId: homework.id,
        );
        return;
      }

      final activityId = item.activityId;
      final occurrenceKey = Bag2SchoolStore.preparationOccurrenceKey(
        date,
        activityId,
      );

      if (Bag2SchoolStore.preparationOccurrenceOverrides.containsKey(
        occurrenceKey,
      )) {
        final overrideItems =
            Bag2SchoolStore.preparationOccurrenceOverrides[occurrenceKey]!;
        final index = overrideItems.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          overrideItems[index] = overrideItems[index].copyWith(
            completed: value,
          );
          Bag2SchoolStore.recordFamilyActivity(
            feature: LocalPermissionFeature.preparation,
            action: 'Edited',
            title: 'Preparation checklist updated',
            message:
                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                '${value ? 'checked' : 'unchecked'} a preparation item '
                'for $activityTitle.',
            childId: Bag2SchoolStore.activeChildId,
            entityId: item.id,
          );
        }
        return;
      }

      // For a recurring template, completion is occurrence-local.
      final activity = _activityFor(item);
      if (activity != null && activity.occursOn(date)) {
        Bag2SchoolStore
                .preparationOccurrenceCompletion['${date.toIso8601String()}|${item.id}'] =
            value;
        Bag2SchoolStore.recordFamilyActivity(
          feature: LocalPermissionFeature.preparation,
          action: 'Edited',
          title: 'Preparation checklist updated',
          message:
              '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
              '${value ? 'checked' : 'unchecked'} a preparation item '
              'for $activityTitle.',
          childId: Bag2SchoolStore.activeChildId,
          entityId: item.id,
        );
        return;
      }

      final index = Bag2SchoolStore.preparations.indexWhere(
        (entry) => entry.id == item.id,
      );
      if (index >= 0) {
        Bag2SchoolStore.preparations[index] = Bag2SchoolStore
            .preparations[index]
            .copyWith(completed: value);
      }
    });
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  // ignore: unused_element
  void _showHistory() {
    final history = _historyGroups();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFCF8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4DAD3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Preparation history',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF302722),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Past preparations stay here so nothing gets lost.',
                    style: TextStyle(color: Color(0xFF756B65)),
                  ),
                  const SizedBox(height: 14),
                  if (history.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No preparation history yet. We'll keep it here for you. 😊",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (_, index) {
                          final group = history[index];
                          return _buildPreparationCard(
                            group,
                            compact: true,
                            history: true,
                          );
                        },
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

  HomeworkItem? _homeworkForPreparationItem(PreparationItem item) {
    for (final homework in Bag2SchoolStore.homeworks) {
      if (item.id == 'prep-${homework.id}') return homework;
    }
    return null;
  }

  bool _isHomeworkPreparation(PreparationItem item) =>
      _homeworkForPreparationItem(item) != null;

  bool _hasEditablePreparations(_PreparationGroup group) =>
      group.items.any((item) => !_isHomeworkPreparation(item));

  Widget _buildPreparationCard(
    _PreparationGroup group, {
    bool compact = false,
    bool history = false,
  }) {
    final items = group.items;
    final progress = _progress(items);
    final color = _activityTint(group.activity);
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = _dayOnly(group.date) == tomorrow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        compact ? 13 : 15,
        compact ? 12 : 15,
        compact ? 13 : 15,
        compact ? 12 : 15,
      ),
      decoration: BoxDecoration(
        color: compact
            ? Colors.white
            : isTomorrow
            ? const Color(0xFFF4F1FF)
            : const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: history
              ? const Color(0xFFE8DDD5)
              : isTomorrow
              ? const Color(0xFFDCD3FF)
              : const Color(0xFFFFD6BD),
          width: compact ? 1 : 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final key = '${group.date.toIso8601String()}|${group.activityId}';
              setState(() {
                if (_expandedPreparationGroups.contains(key)) {
                  _expandedPreparationGroups.remove(key);
                } else {
                  _expandedPreparationGroups.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: compact ? 42 : 46,
                    height: compact ? 42 : 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _homeworkForPreparationId(group.activityId) != null
                          ? Icons.menu_book_outlined
                          : _activityIcon(group.activity),
                      color: color,
                      size: compact ? 21 : 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preparationGroupTitle(group),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF302722),
                          ),
                        ),
                        if (_homeworkForGroup(group) != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E1FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HOMEWORK',
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.0,
                                letterSpacing: .7,
                                color: Color(0xFF7661D8),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _homeworkForGroup(group)!.task,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: Color(0xFF302722),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Builder(
                          builder: (context) {
                            final homework = _homeworkForGroup(group);
                            return Text(
                              homework != null
                                  ? '${group.activity?.title ?? 'No specific activity'} · ${_formatDate(group.date)}'
                                  : '${_formatDate(group.date)}'
                                        '${group.activity == null ? '' : ' · ${_categoryLabel(group.activity)}'}'
                                        '${group.activity == null ? '' : ' · ${_formatTime(group.activity!.startTime)}'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF83766E),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFEFE7E1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: compact ? 15 : 17,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _progressText(items),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF8B7E76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  if (!history && _hasEditablePreparations(group))
                    _preparationActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit preparation',
                      onPressed: () => _editPreparationGroup(group),
                    ),
                  if (!history && _hasEditablePreparations(group))
                    const SizedBox(width: 3),
                  AnimatedRotation(
                    turns:
                        _expandedPreparationGroups.contains(
                          '${group.date.toIso8601String()}|${group.activityId}',
                        )
                        ? .5
                        : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF81736B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _expandedPreparationGroups.contains(
                  '${group.date.toIso8601String()}|${group.activityId}',
                )
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 13, left: 4, right: 4),
              child: Column(
                children: [
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: PreparationChecklistItem(
                        title: item.title,
                        checked: _isOccurrenceChecked(item),
                        isHomework: _homeworkForPreparationItem(item) != null,
                        onChanged: (value) {
                          if (!history) {
                            _toggleItem(item, value);
                          }
                        },
                        onDelete: !history
                            ? () => _deletePreparationItem(item)
                            : null,
                      ),
                    );
                  }),
                  if (!history && items.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        items.first.reminderEnabled &&
                                items.first.reminderDate != null
                            ? 'Bagi reminder · ${_formatDate(items.first.reminderDate!)} '
                                  '${items.first.reminderHour.toString().padLeft(2, '0')}:'
                                  '${items.first.reminderMinute.toString().padLeft(2, '0')}'
                            : 'No reminder set',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B7E76),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preparationActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 17,
            color: danger ? const Color(0xFFCC6B62) : const Color(0xFF7A6B63),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String title, {
    required IconData icon,
    Color color = const Color(0xFF6F625A),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final groups = _groupsForTodayAndFuture();

    final todayGroups = groups.where((group) => group.date == today).toList();
    final tomorrowGroups = groups
        .where((group) => group.date == tomorrow)
        .toList();
    final allUpcomingGroups = groups
        .where((group) => group.date.isAfter(tomorrow))
        .toList();
    final upcomingDates =
        allUpcomingGroups.map((g) => _dayOnly(g.date)).toSet().toList()..sort();

    // Keep the default Preparation page concise: show at most 10 upcoming
    // preparation tasks, ordered by occurrence date and then item order.
    // We keep whole groups when possible, but stop adding groups once the
    // visible task count reaches the limit. 'Show all upcoming' restores
    // the complete list.
    final upcomingGroups = <_PreparationGroup>[];
    if (_showAllUpcoming) {
      upcomingGroups.addAll(allUpcomingGroups);
    } else {
      var taskCount = 0;
      for (final group in allUpcomingGroups) {
        if (taskCount >= 10) break;
        upcomingGroups.add(group);
        taskCount += group.items.length;
      }
    }

    final todayItems = todayGroups.expand((group) => group.items).toList();
    final todayProgress = _progress(todayItems);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Preparation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF302722),
          ),
        ),
        actions: const [],
      ),
      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.preparation,
        title: 'Preparation',
        featureLabel: 'Preparation',
        childId: Bag2SchoolStore.activeChildId,
        // Keep the page readable on wide windows and phones alike.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: const BagiCharacter(),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  15,
                                  12,
                                  15,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EDFF),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFE0D9FF),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 9,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  child: Text(
                                    _bagiMessage,
                                    key: ValueKey(_bagiMessage),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.42,
                                      color: Color(0xFF4D445B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -8,
                                bottom: 13,
                                child: CustomPaint(
                                  size: const Size(10, 16),
                                  painter: PreparationBubbleTailPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TODAY HERO / SPOTLIGHT
                  Container(
                    key: _tutorialPreparationTodayKey,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE7D2), Color(0xFFFFF4E9)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFFFC89E),
                        width: 1.4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A21),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '☀️ TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              todayItems.isEmpty
                                  ? 'All clear'
                                  : '${_done(todayItems)} of ${todayItems.length} ready',
                              style: const TextStyle(
                                color: Color(0xFF7A675B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                todayItems.isEmpty
                                    ? "You're all set for today! 🎉"
                                    : '${(todayProgress * 100).round()}% ready for today',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4C3529),
                                ),
                              ),
                            ),
                            if (todayItems.isNotEmpty)
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: todayProgress.clamp(0.0, 1.0),
                                ),
                                duration: const Duration(milliseconds: 850),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => Text(
                                  '${(value * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFF6F1E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: todayProgress.clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A21),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (todayGroups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              "Nothing needs preparing today. Bagi's got you. 😊",
                              style: TextStyle(
                                color: Color(0xFF715F55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...todayGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildPreparationCard(group),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (tomorrowGroups.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFECE7FF), Color(0xFFF7F4FF)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD2C8F6),
                          width: 1.4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7661D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🌤 TOMORROW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${tomorrowGroups.length} '
                                '${tomorrowGroups.length == 1 ? 'plan' : 'plans'}',
                                style: const TextStyle(
                                  color: Color(0xFF665A80),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          const Padding(
                            padding: EdgeInsets.only(left: 2, bottom: 7),
                            child: Text(
                              'A little head start for tomorrow ✨',
                              style: TextStyle(
                                color: Color(0xFF655A78),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...tomorrowGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildPreparationCard(
                                group,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (upcomingGroups.isNotEmpty) ...[
                    _sectionLabel(
                      'COMING UP',
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF81736B),
                    ),
                    ...upcomingGroups.map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _buildPreparationCard(group, compact: true),
                      ),
                    ),
                    if (allUpcomingGroups.fold<int>(
                          0,
                          (sum, group) => sum + group.items.length,
                        ) >
                        10)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _showAllUpcoming = !_showAllUpcoming,
                          ),
                          icon: Icon(
                            _showAllUpcoming
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            _showAllUpcoming
                                ? 'Show less'
                                : 'Show all upcoming',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF7661D8),
                            minimumSize: const Size(0, 48),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],

                  if (todayGroups.isEmpty &&
                      tomorrowGroups.isEmpty &&
                      upcomingGroups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9DED6)),
                      ),
                      child: const Text(
                        "No upcoming preparations yet. When an activity needs a little planning, "
                        "I'll bring it here. 😊",
                        style: TextStyle(color: Color(0xFF756B65), height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        indicatorColor: const Color(0xFFFFE2CF),
        onDestinationSelected: (index) {
          if (index == 2) return;

          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SchedulePage()),
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

class _PreparationGroup {
  final DateTime date;
  final String activityId;
  final BagActivity? activity;
  final List<PreparationItem> items = <PreparationItem>[];
  bool expanded = false;

  _PreparationGroup({
    required this.date,
    required this.activityId,
    required this.activity,
  });
}

class PreparationOfferCard extends StatefulWidget {
  final BagActivity activity;
  final DateTime preparationDate;
  final VoidCallback onNotNow;
  final void Function(
    List<String> items,
    bool reminderEnabled,
    DateTime reminderDate,
    int reminderHour,
    int reminderMinute,
  )
  onAdd;

  const PreparationOfferCard({
    required this.activity,
    required this.preparationDate,
    required this.onNotNow,
    required this.onAdd,
  });

  @override
  State<PreparationOfferCard> createState() => PreparationOfferCardState();
}

class PreparationOfferCardState extends State<PreparationOfferCard> {
  final TextEditingController _customController = TextEditingController();
  final Set<String> _selectedItems = <String>{};
  // Per-item reminders are hidden; the daily reminder lives in Settings.
  bool _reminderEnabled = false;
  late DateTime _reminderDate;
  int _reminderHour = 18;
  int _reminderMinute = 0;

  List<String> _defaultItems = <String>[];

  String get _activityTypeKey => widget.activity.type.name;

  Future<void> _loadDefaults() async {
    final items = await PreparationDefaults.load(_activityTypeKey);

    if (!mounted) return;

    setState(() {
      _defaultItems = items;
    });
  }

  Future<void> _removeDefault(String item) async {
    final items = await PreparationDefaults.remove(_activityTypeKey, item);

    if (!mounted) return;

    setState(() {
      _defaultItems = items;
      _selectedItems.remove(item);
    });
  }

  @override
  void initState() {
    super.initState();
    _reminderDate = DateTime(
      widget.preparationDate.year,
      widget.preparationDate.month,
      widget.preparationDate.day,
    );
    _defaultItems = PreparationDefaults.builtInFor(_activityTypeKey);
    unawaited(_loadDefaults());
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  // Kept for the hidden per-item reminder UI.
  // ignore: unused_element
  String _formatTime() {
    final h = _reminderHour.toString().padLeft(2, '0');
    final m = _reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Reminder helpers stay for the hidden per-item reminder UI.
  // ignore: unused_element
  String _formatShortDate(DateTime date) {
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

  String _formatDate(DateTime date) {
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
    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _addCustomItem() async {
    final value = _customController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _selectedItems.add(value);
      _customController.clear();
    });

    // Remember the item, so it is offered again next time.
    final items = await PreparationDefaults.add(_activityTypeKey, value);

    if (!mounted) return;

    setState(() {
      _defaultItems = items;
    });
  }

  void _toggleItem(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  // Reminder helpers stay for the hidden per-item reminder UI.
  // ignore: unused_element
  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime(
        widget.preparationDate.year,
        widget.preparationDate.month,
        widget.preparationDate.day,
      ).subtract(const Duration(days: 30)),
      lastDate: DateTime(
        widget.activity.startDate.year,
        widget.activity.startDate.month,
        widget.activity.startDate.day,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme
                .copyWith(primary: const Color(0xFFFF7A21)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _reminderDate = picked);
    }
  }

  // Reminder pickers stay for the per-item reminder that is currently hidden.
  // ignore: unused_element
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme
                .copyWith(primary: const Color(0xFFFF7A21)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 68, height: 68, child: BagiCharacter()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(21),
                          bottomLeft: Radius.circular(21),
                          bottomRight: Radius.circular(21),
                        ),
                      ),
                      child: Text(
                        _messageFor(widget.activity),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.42,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4D4038),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What should we get ready?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Tap to select. Use ✕ to remove an item from your defaults.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8A7E76)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _defaultItems.map((item) {
                  final selected = _selectedItems.contains(item);
                  return InputChip(
                    selected: selected,
                    label: Text(item),
                    onSelected: (_) => _toggleItem(item),
                    onDeleted: () => _removeDefault(item),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    deleteIconColor: const Color(0xFF8A7E76),
                    tooltip: 'Remove "$item" from your defaults',
                    selectedColor: const Color(0xFFFFE1CC),
                    checkmarkColor: const Color(0xFFFF7A21),
                    showCheckmark: true,
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF514640),
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFFF7A21)
                          : const Color(0xFFE4DDD7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              if (_selectedItems.any(
                (item) => !_defaultItems.contains(item),
              )) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _selectedItems
                        .where((item) => !_defaultItems.contains(item))
                        .map((item) {
                          return InputChip(
                            label: Text(item),
                            selected: true,
                            onDeleted: () => _toggleItem(item),
                            deleteIconColor: const Color(0xFFFF7A21),
                            backgroundColor: const Color(0xFFFFF0E3),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF514640),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: const BorderSide(color: Color(0xFFFFC49D)),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustomItem(),
                      decoration: InputDecoration(
                        labelText: 'Anything else?',
                        hintText: 'Type your own item',
                        filled: true,
                        fillColor: const Color(0xFFFFFAF6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5DDD7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5DDD7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: FilledButton(
                      onPressed: _addCustomItem,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE1CC),
                        foregroundColor: const Color(0xFFFF7A21),
                        minimumSize: const Size(52, 48),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF58A879),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prepare on ${_formatDate(widget.preparationDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF45634F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Per-item reminders are hidden; one daily reminder in Settings
              // replaces them.
              const SizedBox(height: 6),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onNotNow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF756B65),
                        side: const BorderSide(color: Color(0xFFE5DDD7)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Maybe later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final items = <String>[..._selectedItems];
                        final custom = _customController.text.trim();
                        if (custom.isNotEmpty) {
                          items.add(custom);
                        }
                        if (items.isEmpty) return;
                        widget.onAdd(
                          items,
                          _reminderEnabled,
                          _reminderDate,
                          _reminderHour,
                          _reminderMinute,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save preparation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _messageFor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return personalizeBagiMessage(
          "Yay, school is sorted, {parent}! 🏫✨ "
          "Want to pick a few little things to get ready? "
          "I'll keep them together for you.",
        );
      case ActivityType.lesson:
        return "Nice, ${activity.title} is sorted! 📚😊 "
            "Let's make the next class feel easy. "
            "Pick what your child should have ready.";
      case ActivityType.extracurricular:
        return "Woohoo, ${activity.title} is on the schedule! 🎉 "
            "Let's get the little things ready now, "
            "so future-you can relax. 😄";
      case ActivityType.exam:
        return "You've got an Exam coming up! 📝 "
            "Let's prepare the study materials and exam tools together.";
      case ActivityType.event:
        return "Ooh, ${activity.title} is coming up! ✨ "
            "Let's choose what we need beforehand and make it easy.";
      default:
        return personalizeBagiMessage(
          "All set, {parent}! 🎒✨ "
          "Let's pick a few things to get ready.",
        );
    }
  }
}

class PreparationChecklistItem extends StatefulWidget {
  final String title;
  final bool checked;
  final bool isHomework;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDelete;

  const PreparationChecklistItem({
    super.key,
    required this.title,
    required this.checked,
    this.isHomework = false,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<PreparationChecklistItem> createState() =>
      _PreparationChecklistItemState();
}

class _PreparationChecklistItemState extends State<PreparationChecklistItem> {
  bool _expanded = false;

  IconData _itemIcon() {
    final value = widget.title.toLowerCase();
    if (value.contains('bottle') ||
        value.contains('drink') ||
        value.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('book') ||
        value.contains('text') ||
        value.contains('lesson')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('lunch') || value.contains('food')) {
      return Icons.lunch_dining_rounded;
    }
    if (value.contains('uniform') ||
        value.contains('jersey') ||
        value.contains('shirt')) {
      return Icons.checkroom_rounded;
    }
    return Icons.backpack_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _itemIcon();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: widget.isHomework
              ? const Color(0xFFF4F0FF)
              : widget.checked
              ? const Color(0xFFF1FAF3)
              : const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isHomework
                ? const Color(0xFFD8CDFB)
                : widget.checked
                ? const Color(0xFFA9D6B8)
                : const Color(0xFFEED8CA),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => widget.onChanged(!widget.checked),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: widget.checked
                    ? const Icon(
                        Icons.check_circle_rounded,
                        size: 28,
                        color: Color(0xFF55A56B),
                      )
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 25,
                        color: Color(0xFFD9C7BB),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.checked
                    ? const Color(0xFFDDF1E3)
                    : widget.isHomework
                    ? const Color(0xFFE5DEFF)
                    : const Color(0xFFFFE6D6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 22,
                color: widget.checked
                    ? const Color(0xFF55A56B)
                    : widget.isHomework
                    ? const Color(0xFF7661D8)
                    : const Color(0xFFFF7A21),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: widget.isHomework
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: const Color(0xFF302722),
                          decoration: widget.checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (widget.title.trim().length > 70)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            _expanded
                                ? 'Tap to collapse'
                                : 'Tap to see full text',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF8B7E76),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.onDelete != null)
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 4),
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFB06F65),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
