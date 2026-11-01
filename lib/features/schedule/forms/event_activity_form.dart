import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../utils/focus.dart';

class EventActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const EventActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<EventActivityForm> createState() => _EventActivityFormState();
}

class _EventActivityFormState extends State<EventActivityForm> {
  final TextEditingController _titleController = TextEditingController();

  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _date = DateTime(
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
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _invalidTime {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
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

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Give the event a name first — then we'll get it on the calendar. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_invalidTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Let's make the end time a little later than the start time. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSaved(
      BagActivity(
        id: 'event-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        type: ActivityType.event,
        startDate: _date,
        startTime: TimeOfDayData(
          hour: _startTime.hour,
          minute: _startTime.minute,
        ),
        endTime: TimeOfDayData(hour: _endTime.hour, minute: _endTime.minute),
        recurrence: const ActivityRecurrence(type: RecurrenceType.none),
        isRoutine: false,
        showIndicator: true,
        indicatorType: ActivityIndicatorType.event,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            const Text(
              'Add Event',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29231F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Field trips, parent meetings, report cards, graduation, and other special days.",
              style: TextStyle(color: Color(0xFF756B65), height: 1.35),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _titleController.clear();
                    setState(() {});
                  },
                ),
                labelText: 'Event name',
                hintText: 'e.g. Parent Meeting',
                prefixIcon: const Icon(Icons.event_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(
                      'Start\n${_formatTime(_startTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(
                      'End\n${_formatTime(_endTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add to schedule',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
