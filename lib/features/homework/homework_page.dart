import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/activity_models.dart';
import '../../models/family_models.dart';
import '../../utils/controllers.dart';
import '../../utils/focus.dart';
import '../../widgets/bagi_character.dart';
import '../../widgets/bagi_tutorial_overlay.dart';
import '../../widgets/bubble_tail_painters.dart';
import '../preparation/preparation_page.dart';
import '../schedule/schedule_page.dart';
import '../settings/settings_page.dart';
import 'homework_history_page.dart';

// Homework screen: to-do list, completed tab, add and edit sheets.
// Extracted from lib/main.dart (step 5b).

class HomeworkPage extends StatefulWidget {
  final bool tutorial;
  final int tutorialStep;

  const HomeworkPage({
    super.key,
    this.tutorial = false,
    this.tutorialStep = 13,
  });

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _tutorialHomeworkAddKey = GlobalKey();
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _orangeSoft = Color(0xFFFFE8D5);
  static const Color _peach = Color(0xFFFFF1E6);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF29231F);
  static const Color _muted = Color(0xFF756B65);

  bool _showCompleted = false;
  late final AnimationController _bagiController;
  Timer? _bagiTimer;
  int _messageIndex = 0;
  int _messageVersion = 0;
  String _visibleMessage = '';

  final List<String> _bagiMessages = const [
    "Yay! 🎉 You're all caught up!",
    "No homework waiting right now. Enjoy your free time! ✨",
    "Let's take homework one little step at a time! 📚",
    "I'm here to help you stay on track! 🎒",
  ];

  @override
  void initState() {
    super.initState();
    _bagiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _typeMessage(_bagiMessages.first);
    _bagiTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _messageIndex = (_messageIndex + 1) % _bagiMessages.length;
      _typeMessage(_bagiMessages[_messageIndex]);
    });
    if (widget.tutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_runHomeworkTutorial());
      });
    }
  }

  Future<void> _runHomeworkTutorial() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final action = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _tutorialHomeworkAddKey,
      stepLabel: 'Step ${widget.tutorialStep} of ${widget.tutorialStep + 4}',
      title: 'Homework',
      message: 'Homework is grouped by due date. Tap the plus button to add a task and its due date.',
    );
    if (mounted) Navigator.of(context).pop(action != BagiTutorialAction.skip);
  }

  @override
  void dispose() {
    _bagiTimer?.cancel();
    _bagiController.dispose();
    super.dispose();
  }

  void _typeMessage(String message) {
    final version = ++_messageVersion;
    setState(() => _visibleMessage = '');
    final characters = message.runes.toList();
    for (var i = 1; i <= characters.length; i++) {
      Future.delayed(Duration(milliseconds: 28 * i), () {
        if (!mounted || version != _messageVersion) return;
        setState(
          () => _visibleMessage = String.fromCharCodes(characters.take(i)),
        );
      });
    }
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateLabel(DateTime date) {
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

  String _dueLabel(HomeworkItem item) {
    final today = _dayOnly(DateTime.now());
    final due = _dayOnly(item.dueDate);
    final diff = due.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${_dateLabel(due)}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _homeworkStatusLabel(HomeworkItem item) {
    final today = _dayOnly(DateTime.now());
    final due = _dayOnly(item.dueDate);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${_dateLabel(due)}';
  }

  List<HomeworkItem> _openHomework() {
    return Bag2SchoolStore.homeworks.where((h) => !h.completed).toList()
      ..sort((a, b) {
        final d = _dayOnly(a.dueDate).compareTo(_dayOnly(b.dueDate));
        return d != 0 ? d : a.createdAt.compareTo(b.createdAt);
      });
  }

  List<HomeworkItem> _todayHomework() {
    final today = _dayOnly(DateTime.now());
    return _openHomework()
        .where((h) => _sameDay(_dayOnly(h.dueDate), today))
        .toList();
  }

  List<HomeworkItem> _tomorrowHomework() {
    final tomorrow = _dayOnly(DateTime.now()).add(const Duration(days: 1));
    return _openHomework()
        .where((h) => _sameDay(_dayOnly(h.dueDate), tomorrow))
        .toList();
  }

  List<HomeworkItem> _upcomingHomework() {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    return _openHomework().where((h) {
      final due = _dayOnly(h.dueDate);
      return due.isAfter(tomorrow);
    }).toList();
  }

  List<HomeworkItem> _overdueHomework() {
    final today = _dayOnly(DateTime.now());
    return _openHomework()
        .where((h) => _dayOnly(h.dueDate).isBefore(today))
        .toList()
      ..sort((a, b) => _dayOnly(b.dueDate).compareTo(_dayOnly(a.dueDate)));
  }

  List<HomeworkItem> _completedItems() {
    return Bag2SchoolStore.homeworks.where((h) => h.completed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _toggleDone(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(
        context,
        'change',
        featureLabel: 'homework',
      );
      return;
    }
    final index = Bag2SchoolStore.homeworks.indexWhere((h) => h.id == item.id);
    if (index < 0) return;
    setState(() {
      // Homework completion is independent from Preparation completion.
      Bag2SchoolStore.homeworks[index] = item.copyWith(
        completed: !item.completed,
      );
    });
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  Future<void> _undoCompleted(HomeworkItem item) async {
    final index = Bag2SchoolStore.homeworks.indexWhere((h) => h.id == item.id);
    if (index < 0) return;
    setState(() {
      Bag2SchoolStore.homeworks[index] = item.copyWith(completed: false);
    });
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  void _removeHomeworkFromPreparation(HomeworkItem item) {
    final prepId = 'prep-${item.id}';
    Bag2SchoolStore.preparations.removeWhere((p) => p.id == prepId);
    for (final entry
        in Bag2SchoolStore.preparationOccurrenceOverrides.entries.toList()) {
      final updated = entry.value.where((p) => p.id != prepId).toList();
      Bag2SchoolStore.preparationOccurrenceOverrides[entry.key] = updated;
    }
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  void _addHomeworkToPreparation(HomeworkItem item) {
    if (item.relatedActivityId == null) return;
    final key = Bag2SchoolStore.preparationOccurrenceKey(
      item.dueDate,
      item.relatedActivityId!,
    );
    final occurrenceItems = Bag2SchoolStore.preparationsForOccurrence(
      item.dueDate,
      item.relatedActivityId!,
    );
    occurrenceItems.removeWhere((p) => p.id == 'prep-${item.id}');
    occurrenceItems.add(
      PreparationItem(
        id: 'prep-${item.id}',
        activityId: item.relatedActivityId!,
        title: item.task,
        preparationDate: item.dueDate,
        reminderEnabled: item.reminderEnabled,
        reminderDate: item.reminderDate,
        reminderHour: item.reminderHour,
        reminderMinute: item.reminderMinute,
      ),
    );
    Bag2SchoolStore.preparationOccurrenceOverrides[key] = occurrenceItems;
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  Future<void> _delete(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: 'homework',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cream,
        title: const Text('Delete homework?'),
        content: Text('Remove “${item.task}” from homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      Bag2SchoolStore.homeworks.removeWhere((h) => h.id == item.id);
      _removeHomeworkFromPreparation(item);
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.homework,
      action: 'Deleted',
      title: 'Homework deleted',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'deleted ${Bag2SchoolStore.activeChild.name} [${item.task}].',
      childId: Bag2SchoolStore.activeChildId,
      entityId: item.id,
    );
    Bag2SchoolStore.persistSchoolDataSoon();
  }

  Widget _bagiHero() {
    return AnimatedBuilder(
      animation: _bagiController,
      builder: (context, child) {
        final y = sin(_bagiController.value * pi) * 5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.translate(
              offset: Offset(0, -y),
              child: SizedBox(
                width: 128,
                height: 128,
                child: const BagiCharacter(),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(child: _speechBubble(_visibleMessage)),
          ],
        );
      },
    );
  }

  Widget _speechBubble(String text) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(20, 15, 18, 15),
          decoration: BoxDecoration(
            color: _peach,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(8),
            ),
            border: Border.all(color: const Color(0xFFFFC18F), width: 1.2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              text.isEmpty ? '...' : text,
              key: ValueKey(text),
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          left: -9,
          bottom: 12,
          child: CustomPaint(
            size: const Size(18, 18),
            painter: OrangeBubbleTailPainter(),
          ),
        ),
      ],
    );
  }

  Widget _segmentedTabs() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              'To Do',
              !_showCompleted,
              () => setState(() => _showCompleted = false),
            ),
          ),
          Expanded(
            child: _tabButton(
              'Completed',
              _showCompleted,
              () => setState(() => _showCompleted = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _orange : _muted,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required bool completed}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD8B9)),
      ),
      child: Column(
        children: [
          Container(
            width: 116,
            height: 96,
            decoration: BoxDecoration(
              color: _orangeSoft,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.checklist_rounded, size: 65, color: _orange),
                Positioned(
                  right: 19,
                  bottom: 12,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            completed
                ? 'No completed homework yet.'
                : 'No homework waiting right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            completed
                ? 'We’ll celebrate it here! 🎉'
                : 'Enjoy your free time! 🌟',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _homeworkSection({
    required String title,
    required List<HomeworkItem> items,
    Color? titleColor,
    int? badgeCount,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isToday = title == 'TODAY';
    final isTomorrow = title == 'TOMORROW';
    final isOverdue = title == 'OVERDUE';
    final color =
        titleColor ??
        (isToday
            ? _orange
            : isTomorrow
            ? const Color(0xFF7661D8)
            : isOverdue
            ? const Color(0xFFC95757)
            : const Color(0xFF4C8FD9));
    final background = isToday
        ? const Color(0xFFFFEBDD)
        : isTomorrow
        ? const Color(0xFFF0EDFF)
        : isOverdue
        ? const Color(0xFFFFEEEE)
        : const Color(0xFFEEF6FF);
    final border = isToday
        ? const Color(0xFFFFB87A)
        : isTomorrow
        ? const Color(0xFFD2C8F6)
        : isOverdue
        ? const Color(0xFFF1BABA)
        : const Color(0xFFC8DDF2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: isToday ? 1.4 : 1),
        boxShadow: isToday
            ? const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 9),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                    color: color,
                  ),
                ),
                const Spacer(),
                if (badgeCount != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0E0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC95757),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...items.map(_homeworkCard),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _homeworkEmptyHint() {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0C7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _orange, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              "Nothing due here. You're doing great! ✨",
              style: TextStyle(
                fontSize: 12.5,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeworkCard(HomeworkItem item) {
    final prepExists = Bag2SchoolStore.preparations.any(
      (p) => p.id == 'prep-${item.id}',
    );

    BagActivity? relatedActivity;
    if (item.relatedActivityId != null) {
      for (final activity in Bag2SchoolStore.activities) {
        if (activity.id == item.relatedActivityId) {
          relatedActivity = activity;
          break;
        }
      }
    }

    if (item.completed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB9DFC5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8F0DF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF4C956C),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.task,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF31583E),
                        ),
                      ),
                      if (item.subject.isNotEmpty)
                        Text(
                          item.subject,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5E8068),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _completedInfo(
                  Icons.calendar_today_outlined,
                  _dateLabel(item.dueDate),
                ),
                if (item.dueTime != null)
                  _completedInfo(
                    Icons.schedule_outlined,
                    '${item.dueTime!.hour.toString().padLeft(2, '0')}:${item.dueTime!.minute.toString().padLeft(2, '0')}',
                  ),
                if (relatedActivity != null)
                  _completedInfo(
                    Icons.link_rounded,
                    _relatedActivityLabel(relatedActivity!),
                  ),
              ],
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                item.notes,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF5E8068),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _undoCompleted(item),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4C956C),
                ),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD8B9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _orangeSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _orange),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.task,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    if (item.subject.isNotEmpty)
                      Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconColor: _muted,
                onSelected: (v) {
                  if (v == 'edit') _editHomework(item);
                  if (v == 'delete') _delete(item);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 7,
            children: [
              _smallInfo(
                Icons.calendar_today_outlined,
                _homeworkStatusLabel(item),
              ),
              if (item.dueTime != null)
                _smallInfo(
                  Icons.schedule_outlined,
                  '${item.dueTime!.hour.toString().padLeft(2, '0')}:${item.dueTime!.minute.toString().padLeft(2, '0')}',
                ),
              if (relatedActivity != null)
                _smallInfo(
                  Icons.link_rounded,
                  _relatedActivityLabel(relatedActivity!),
                ),
              if (item.reminderEnabled)
                _smallInfo(Icons.notifications_none_outlined, 'Reminder'),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              item.notes,
              style: const TextStyle(
                fontSize: 12.5,
                color: _muted,
                height: 1.35,
              ),
            ),
          ],
          if (prepExists) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.backpack_outlined, size: 16, color: _orange),
                SizedBox(width: 4),
                Text(
                  'Added to preparation',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A5D31),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _toggleDone(item),
              style: TextButton.styleFrom(foregroundColor: _orange),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedInfo(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF2E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C956C)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF31583E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: _orange),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          textCapitalization: capitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9B918B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFFFC18F),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _orange, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selector({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFC18F), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: _orange, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              trailing ??
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  String _relatedActivityLabel(
    BagActivity activity, {
    DateTime? occurrenceDate,
  }) {
    final start =
        '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}';
    // The due date is already visible in the Homework form, so keep the
    // dropdown label compact and prevent the selected row from overflowing.
    return '${activity.title} · $start–$end';
  }

  Future<void> _addHomework() async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(
        context,
        'add',
        featureLabel: 'homework',
        feature: LocalPermissionFeature.homework,
        requestEdit: true,
      );
      return;
    }
    final task = TextEditingController();
    final subject = TextEditingController();
    final notes = TextEditingController();
    DateTime dueDate = _dayOnly(DateTime.now());
    TimeOfDayData? dueTime;
    String? relatedActivityId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Related Activity is scoped to the selected homework due date.
          // For a recurring Mon-Fri activity, this produces only the single
          // occurrence for the selected date instead of filling the dropdown
          // with dozens of repeated occurrences.
          final activityOptions =
              Bag2SchoolStore.activities
                  .where(
                    (activity) =>
                        activity.type != ActivityType.exam &&
                        activity.occursOn(dueDate),
                  )
                  .map(
                    (activity) => _HomeworkActivityOption(
                      activity: activity,
                      occurrenceDate: dueDate,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.activity.startMinutes().compareTo(
                    b.activity.startMinutes(),
                  ),
                );

          // If the due date changes, an activity selected for the previous
          // date is no longer valid. Clear it before rendering the dropdown.
          if (relatedActivityId != null &&
              !activityOptions.any(
                (option) => option.value == relatedActivityId,
              )) {
            relatedActivityId = null;
          }

          return SafeArea(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 760),
              decoration: const BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D8CC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 3),
                          child: SizedBox(
                            width: 105,
                            height: 105,
                            child: const BagiCharacter(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _speechBubble(
                            'Let’s add a homework! 📚\nBagi will help you keep it simple.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                      decoration: BoxDecoration(
                        color: _peach,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFFD2AD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formField(
                            controller: task,
                            label: 'What do you need to do?',
                            hint: 'e.g. Mandarin worksheet',
                            icon: Icons.menu_book_rounded,
                            autofocus: true,
                          ),
                          const SizedBox(height: 18),
                          _formField(
                            controller: subject,
                            label: 'Subject (optional)',
                            hint: 'e.g. Mandarin',
                            icon: Icons.school_rounded,
                            capitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 21,
                                color: _orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Deadline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _selector(
                                icon: Icons.calendar_today_outlined,
                                label: _dateLabel(dueDate),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 3650),
                                    ),
                                  );
                                  if (picked == null) return;
                                  setSheetState(() {
                                    dueDate = _dayOnly(picked);
                                  });
                                },
                              ),
                              const SizedBox(width: 9),
                              _selector(
                                icon: Icons.schedule_outlined,
                                label: dueTime == null
                                    ? 'Any time'
                                    : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}',
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: dueTime?.hour ?? 17,
                                      minute: dueTime?.minute ?? 0,
                                    ),
                                  );
                                  if (picked == null) return;
                                  setSheetState(
                                    () => dueTime = TimeOfDayData(
                                      hour: picked.hour,
                                      minute: picked.minute,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (activityOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                13,
                                14,
                                13,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5ED),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFFFC18F),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: _orange,
                                    size: 21,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'No activity is scheduled on this date. You can still save the homework without linking it to an activity.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: _ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: relatedActivityId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Linked school activity (optional)',
                                prefixIcon: const Icon(
                                  Icons.link_rounded,
                                  color: _orange,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: _orange,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              hint: const Text('Not linked to any activity'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Not linked to any activity'),
                                ),
                                ...activityOptions.map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(
                                      _relatedActivityLabel(
                                        option.activity,
                                        occurrenceDate: option.occurrenceDate,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setSheetState(() {
                                  relatedActivityId =
                                      (value == null || value.isEmpty)
                                      ? null
                                      : value;
                                });
                              },
                            ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(2, 8, 2, 0),
                            child: Text(
                              'Links this homework to a school activity, so it also shows up in that day\'s preparation.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: _muted,
                              ),
                            ),
                          ),
                          if (relatedActivityId != null) ...[
                            const SizedBox(height: 10),
                            Builder(
                              builder: (_) {
                                final linked = activityOptions
                                    .where((o) => o.value == relatedActivityId)
                                    .toList();
                                if (linked.isEmpty)
                                  return const SizedBox.shrink();
                                final option = linked.first;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    11,
                                    14,
                                    11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _orangeSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.event_available_rounded,
                                        color: _orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _relatedActivityLabel(
                                            option.activity,
                                            occurrenceDate:
                                                option.occurrenceDate,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            height: 1.3,
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          // Per-item reminders are hidden: one daily reminder in
                          // Settings replaces them (see docs/NOTIFICATIONS.md).
                          const SizedBox(height: 18),
                          _formField(
                            controller: notes,
                            label: 'Anything else? (optional)',
                            hint: 'Add a note...',
                            icon: Icons.edit_note_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: task,
                            builder: (context, value, _) {
                              final enabled = value.text.trim().isNotEmpty;
                              return Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await settleDialogFocus();
                                          if (!sheetContext.mounted) return;
                                          Navigator.pop(sheetContext, false);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _muted,
                                          side: const BorderSide(
                                            color: Color(0xFFD9CCC4),
                                            width: 1.3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 56,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: enabled
                                              ? _orange
                                              : const Color(0xFFE8E1DD),
                                          foregroundColor: enabled
                                              ? Colors.white
                                              : const Color(0xFFA9A19D),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                        ),
                                        onPressed: !enabled
                                            ? null
                                            : () async {
                                                final id =
                                                    'homework-${DateTime.now().microsecondsSinceEpoch}';
                                                final item = HomeworkItem(
                                                  id: id,
                                                  task: task.text.trim(),
                                                  subject: subject.text.trim(),
                                                  dueDate: dueDate,
                                                  dueTime: dueTime,
                                                  // Per-item reminders are
                                                  // hidden; the daily reminder
                                                  // lives in Settings.
                                                  reminderEnabled: false,
                                                  reminderDate: null,
                                                  reminderHour: 18,
                                                  reminderMinute: 0,
                                                  notes: notes.text.trim(),
                                                  relatedActivityId:
                                                      relatedActivityId,
                                                  createdAt: DateTime.now(),
                                                );
                                                Bag2SchoolStore.homeworks.add(
                                                  item,
                                                );
                                                _addHomeworkToPreparation(item);

                                                Bag2SchoolStore.recordFamilyActivity(
                                                  feature:
                                                      LocalPermissionFeature
                                                          .homework,
                                                  action: 'Added',
                                                  title: 'Homework added',
                                                  message:
                                                      '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                                      'added ${Bag2SchoolStore.activeChild.name} [${item.task}].',
                                                  childId: Bag2SchoolStore
                                                      .activeChildId,
                                                  entityId: item.id,
                                                );
                                                Bag2SchoolStore.persistSchoolDataSoon();

                                                await settleDialogFocus();
                                                if (!sheetContext.mounted)
                                                  return;
                                                Navigator.pop(
                                                  sheetContext,
                                                  true,
                                                );
                                              },
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text(
                                          'Save & Close',
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeControllersAfterRoute([task, subject, notes]);
    });
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _editHomework(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(context, 'edit', featureLabel: 'homework');
      return;
    }
    final task = TextEditingController(text: item.task);
    final subject = TextEditingController(text: item.subject);
    DateTime dueDate = _dayOnly(item.dueDate);
    TimeOfDayData? dueTime = item.dueTime;
    bool reminder = item.reminderEnabled;
    DateTime reminderDate =
        item.reminderDate ?? dueDate.subtract(const Duration(days: 1));
    int reminderHour = item.reminderHour;
    int reminderMinute = item.reminderMinute;
    String? relatedActivityId = item.relatedActivityId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final activityOptions =
              Bag2SchoolStore.activities
                  .where(
                    (activity) =>
                        activity.type != ActivityType.exam &&
                        activity.occursOn(dueDate),
                  )
                  .where(
                    (activity) => !Bag2SchoolStore.isOccurrenceCancelled(
                      dueDate,
                      activity.id,
                    ),
                  )
                  .map(
                    (activity) => _HomeworkActivityOption(
                      activity: activity,
                      occurrenceDate: dueDate,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.activity.startMinutes().compareTo(
                    b.activity.startMinutes(),
                  ),
                );
          if (relatedActivityId != null &&
              !activityOptions.any((o) => o.value == relatedActivityId)) {
            relatedActivityId = null;
          }
          return SafeArea(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 720),
              decoration: const BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D8CC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: const BagiCharacter(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _speechBubble(
                            'Let’s make a little update! ✏️',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                      decoration: BoxDecoration(
                        color: _peach,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFFD2AD)),
                      ),
                      child: Column(
                        children: [
                          _formField(
                            controller: task,
                            label: 'What do you need to do?',
                            hint: 'e.g. Mandarin worksheet',
                            icon: Icons.menu_book_rounded,
                          ),
                          const SizedBox(height: 18),
                          _formField(
                            controller: subject,
                            label: 'Subject (optional)',
                            hint: 'e.g. Mandarin',
                            icon: Icons.school_rounded,
                            capitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 18),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'When is it due?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _selector(
                                icon: Icons.calendar_today_outlined,
                                label: _dateLabel(dueDate),
                                onTap: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 3650),
                                    ),
                                  );
                                  if (p == null) return;
                                  final newDate = _dayOnly(p);
                                  setSheetState(() {
                                    dueDate = newDate;
                                    if (reminderDate.isAfter(dueDate))
                                      reminderDate = dueDate;
                                    if (relatedActivityId != null) {
                                      final stillValid = Bag2SchoolStore
                                          .activities
                                          .any(
                                            (a) =>
                                                a.id == relatedActivityId &&
                                                a.occursOn(newDate) &&
                                                !Bag2SchoolStore.isOccurrenceCancelled(
                                                  newDate,
                                                  a.id,
                                                ),
                                          );
                                      if (!stillValid) relatedActivityId = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 9),
                              _selector(
                                icon: Icons.schedule_outlined,
                                label: dueTime == null
                                    ? 'Any time'
                                    : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}',
                                onTap: () async {
                                  final p = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: dueTime?.hour ?? 17,
                                      minute: dueTime?.minute ?? 0,
                                    ),
                                  );
                                  if (p == null) return;
                                  setSheetState(
                                    () => dueTime = TimeOfDayData(
                                      hour: p.hour,
                                      minute: p.minute,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (activityOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7F1),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFFFDEC5),
                                ),
                              ),
                              child: const Text(
                                'No activity is scheduled on this date. The homework can stay unlinked.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<String?>(
                              value: relatedActivityId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Linked school activity (optional)',
                                prefixIcon: const Icon(
                                  Icons.link_rounded,
                                  color: _orange,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Not linked to any activity'),
                                ),
                                ...activityOptions.map(
                                  (option) => DropdownMenuItem<String?>(
                                    value: option.value,
                                    child: Text(
                                      _relatedActivityLabel(
                                        option.activity,
                                        occurrenceDate: dueDate,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setSheetState(
                                () => relatedActivityId = value,
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(2, 8, 2, 0),
                            child: Text(
                              'Links this homework to a school activity, so it also shows up in that day\'s preparation.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: _muted,
                              ),
                            ),
                          ),
                          if (relatedActivityId != null) ...[
                            const SizedBox(height: 7),
                            Builder(
                              builder: (_) {
                                final linked = activityOptions
                                    .where((o) => o.value == relatedActivityId)
                                    .toList();
                                if (linked.isEmpty)
                                  return const SizedBox.shrink();
                                return Text(
                                  _relatedActivityLabel(
                                    linked.first.activity,
                                    occurrenceDate: dueDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          // Per-item reminders are hidden; one daily reminder
                          // in Settings replaces them.
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await settleDialogFocus();
                                      if (!sheetContext.mounted) return;
                                      Navigator.pop(sheetContext, false);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _muted,
                                      side: const BorderSide(
                                        color: Color(0xFFD9CCC4),
                                        width: 1.3,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 56,
                                  child: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: task,
                                    builder: (context, value, _) => FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            value.text.trim().isEmpty
                                            ? const Color(0xFFE8E1DD)
                                            : _orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                      ),
                                      onPressed: value.text.trim().isEmpty
                                          ? null
                                          : () async {
                                              final index = Bag2SchoolStore
                                                  .homeworks
                                                  .indexWhere(
                                                    (h) => h.id == item.id,
                                                  );
                                              if (index < 0) return;
                                              _removeHomeworkFromPreparation(
                                                item,
                                              );
                                              final updated = item.copyWith(
                                                task: task.text.trim(),
                                                subject: subject.text.trim(),
                                                dueDate: dueDate,
                                                dueTime: dueTime,
                                                reminderEnabled: reminder,
                                                reminderDate: reminder
                                                    ? reminderDate
                                                    : null,
                                                reminderHour: reminderHour,
                                                reminderMinute: reminderMinute,
                                                clearReminderDate: !reminder,
                                                relatedActivityId:
                                                    relatedActivityId,
                                                clearRelatedActivity:
                                                    relatedActivityId == null,
                                              );
                                              Bag2SchoolStore.homeworks[index] =
                                                  updated;
                                              _addHomeworkToPreparation(
                                                updated,
                                              );

                                              Bag2SchoolStore.recordFamilyActivity(
                                                feature: LocalPermissionFeature
                                                    .homework,
                                                action: 'Edited',
                                                title: 'Homework updated',
                                                message:
                                                    '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                                    'updated ${Bag2SchoolStore.activeChild.name} [${updated.task}].',
                                                childId: Bag2SchoolStore
                                                    .activeChildId,
                                                entityId: updated.id,
                                              );
                                              Bag2SchoolStore.persistSchoolDataSoon();

                                              await settleDialogFocus();
                                              if (!sheetContext.mounted) return;
                                              Navigator.pop(sheetContext, true);
                                            },
                                      icon: const Icon(Icons.check_rounded),
                                      label: const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeControllersAfterRoute([task, subject]);
    });
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedItems();
    final todayItems = _todayHomework();
    final tomorrowItems = _tomorrowHomework();
    final upcomingItems = _upcomingHomework();
    final overdueItems = _overdueHomework();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Homework',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        actions: [
          if (LocalAuthorization.canView(
            LocalPermissionFeature.homework,
            childId: Bag2SchoolStore.activeChildId,
          ))
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeworkHistoryPage()),
              ),
              icon: const Icon(Icons.history_rounded, color: _orange),
              label: const Text(
                'History',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.homework,
        title: 'Homework',
        featureLabel: 'Homework',
        childId: Bag2SchoolStore.activeChildId,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text(
                'A little step at a time. ✨',
                style: TextStyle(
                  fontSize: 17,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _bagiHero(),
              const SizedBox(height: 6),
              _segmentedTabs(),
              const SizedBox(height: 18),
              if (_showCompleted)
                if (completed.isEmpty)
                  _emptyState(completed: true)
                else
                  ...completed.map(_homeworkCard)
              else ...[
                _homeworkSection(title: 'TODAY', items: todayItems),
                _homeworkSection(
                  title: 'TOMORROW',
                  items: tomorrowItems,
                  titleColor: const Color(0xFFE39A24),
                ),
                _homeworkSection(
                  title: 'UPCOMING',
                  items: upcomingItems,
                  titleColor: _muted,
                ),
                _homeworkSection(
                  title: 'OVERDUE',
                  items: overdueItems,
                  titleColor: const Color(0xFFC95757),
                  badgeCount: overdueItems.length,
                ),
                if (todayItems.isEmpty &&
                    tomorrowItems.isEmpty &&
                    upcomingItems.isEmpty &&
                    overdueItems.isEmpty)
                  _homeworkEmptyHint(),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      floatingActionButton:
          LocalAuthorization.canView(
            LocalPermissionFeature.homework,
            childId: Bag2SchoolStore.activeChildId,
          )
          ? FloatingActionButton(
              key: _tutorialHomeworkAddKey,
              heroTag: 'homework_add_fab',
              onPressed: _addHomework,
              tooltip: 'Add Homework',
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: const Color(0xFFFFF1E8),
        indicatorColor: _orangeSoft,
        onDestinationSelected: (index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchedulePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreparationPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Preparation',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeworkActivityOption {
  final BagActivity activity;
  final DateTime occurrenceDate;
  const _HomeworkActivityOption({
    required this.activity,
    required this.occurrenceDate,
  });

  // The dropdown is scoped to ONE due date, so each activity can safely use
  // its real activity id as the DropdownButton value. This also avoids the
  // duplicate-value crash for recurring Mon-Fri activities.
  String get value => activity.id;
}
