import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/store.dart';
import '../../../models/activity_models.dart';
import '../../../utils/focus.dart';
import '../widgets/conflict_card.dart';

class SchoolActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const SchoolActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<SchoolActivityForm> createState() => _SchoolActivityFormState();
}

class _SchoolActivityFormState extends State<SchoolActivityForm> {
  final TextEditingController _titleController = TextEditingController(
    text: 'School',
  );

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);

  RecurrenceType _recurrenceType = RecurrenceType.weekdays;
  final Set<int> _selectedWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One time';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.custom:
        return 'Custom days';
      default:
        return 'Every week';
    }
  }

  ActivityRecurrence _buildRecurrence() {
    switch (_recurrenceType) {
      case RecurrenceType.weekdays:
        return const ActivityRecurrence(type: RecurrenceType.weekdays);

      case RecurrenceType.weekly:
        return const ActivityRecurrence(type: RecurrenceType.weekly);

      case RecurrenceType.biweekly:
        return const ActivityRecurrence(type: RecurrenceType.biweekly);

      case RecurrenceType.custom:
        return ActivityRecurrence(
          type: RecurrenceType.custom,
          weekdays: _selectedWeekdays.toList()..sort(),
        );

      case RecurrenceType.none:
        return const ActivityRecurrence(type: RecurrenceType.none);

      default:
        return const ActivityRecurrence(type: RecurrenceType.weekly);
    }
  }

  bool _hasTimeError() {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  BagActivity _buildActivity() {
    return BagActivity(
      id: 'school-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty
          ? 'School'
          : _titleController.text.trim(),
      type: ActivityType.school,
      startDate: _startDate,
      startTime: TimeOfDayData(
        hour: _startTime.hour,
        minute: _startTime.minute,
      ),
      endTime: TimeOfDayData(hour: _endTime.hour, minute: _endTime.minute),
      recurrence: _buildRecurrence(),
      isRoutine: true,
      showIndicator: false,
      indicatorType: ActivityIndicatorType.none,
    );
  }

  void _save() {
    if (_saving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this class a name first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasTimeError()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time should be later than start time.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_recurrenceType == RecurrenceType.custom && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one day.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final candidate = _buildActivity();

    final conflicts = const ActivityConflictDetector().findConflicts(
      candidate: candidate,
      existingActivities: Bag2SchoolStore.activities,
    );

    if (conflicts.isNotEmpty) {
      _showConflictWarning(candidate, conflicts.first);
      return;
    }

    _finishSave(candidate);
  }

  void _showConflictWarning(BagActivity candidate, ActivityConflict conflict) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Schedule conflict',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: BagiConflictCard(
                conflict: conflict,
                onKeepBoth: () {
                  Navigator.pop(context);
                  _finishSave(candidate);
                },
                onAdjust: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _finishSave(BagActivity activity) {
    setState(() => _saving = true);
    widget.onSaved(activity);
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD7BF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF756B65)),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29231F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatOption(
    BuildContext dialogContext,
    RecurrenceType value,
    String label,
  ) {
    final selected = _recurrenceType == value;

    return InkWell(
      onTap: () => Navigator.pop(dialogContext, value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE7D2) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF7A21) : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: const Color(0xFF29231F),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF7A21),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayChip(int weekday, String label) {
    final selected = _selectedWeekdays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: const Color(0xFFFFDCC6),
      checkmarkColor: const Color(0xFFFF7A21),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFFFF6B1A) : const Color(0xFF625851),
      ),
      side: const BorderSide(color: Color(0xFFE5DDD7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Color(0xFFFF7A21),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add school schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _sectionTitle('Activity name'),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _titleController.clear();
                    setState(() {});
                  },
                ),
                hintText: 'School',
                filled: true,
                fillColor: const Color(0xFFFFFAF6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5DDD7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5DDD7)),
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Starts on'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5DDD7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_startDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Color(0xFFB8ADA5)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Time'),
            Row(
              children: [
                _timeCard(
                  label: 'Start',
                  time: _startTime,
                  onTap: () => _pickTime(start: true),
                ),
                const SizedBox(width: 10),
                _timeCard(
                  label: 'End',
                  time: _endTime,
                  onTap: () => _pickTime(start: false),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _sectionTitle('Repeats'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final selected = await showDialog<RecurrenceType>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.62),
                  builder: (dialogContext) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFF7A21),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'How often?',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29231F),
                                  ),
                                ),
                              ),
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekdays,
                              'Every weekday (Mon–Fri)',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekly,
                              'Every week',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.biweekly,
                              'Every 2 weeks',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.custom,
                              'Custom days',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.none,
                              'One time',
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (selected != null) {
                  setState(() => _recurrenceType = selected);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF7A21), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: Color(0xFFFF7A21)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recurrenceLabel(_recurrenceType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29231F),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8A7E76),
                    ),
                  ],
                ),
              ),
            ),

            if (_recurrenceType == RecurrenceType.custom) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _weekdayChip(DateTime.monday, 'Mon'),
                  _weekdayChip(DateTime.tuesday, 'Tue'),
                  _weekdayChip(DateTime.wednesday, 'Wed'),
                  _weekdayChip(DateTime.thursday, 'Thu'),
                  _weekdayChip(DateTime.friday, 'Fri'),
                  _weekdayChip(DateTime.saturday, 'Sat'),
                  _weekdayChip(DateTime.sunday, 'Sun'),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Text(
              'School is treated as a routine, so it will not create a calendar dot.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            await settleDialogFocus();
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save School Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
