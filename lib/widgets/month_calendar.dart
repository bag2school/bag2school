import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/activity_models.dart';

// Month calendar with activity, homework and exam dots. Extracted from
// lib/main.dart (step 5a of the split).

class Bag2SchoolMonthCalendar extends StatefulWidget {
  final DateTime selectedDate;

  const Bag2SchoolMonthCalendar({super.key, required this.selectedDate});

  @override
  State<Bag2SchoolMonthCalendar> createState() =>
      _Bag2SchoolMonthCalendarState();
}

class _Bag2SchoolMonthCalendarState extends State<Bag2SchoolMonthCalendar> {
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();

    displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
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

  int daysInMonth() {
    return DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
  }

  List<CalendarIndicator> indicatorsFor(DateTime date) {
    // Month view is driven by real activities only.
    // Preparation items never create month-view dots.
    final indicators = <IndicatorType>[];

    // Keep month view in sync with real activities.
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
          // Preparation is not a calendar event.
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
    final hasHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate;
    });
    if (hasHomework && !indicators.contains(IndicatorType.homework)) {
      indicators.add(IndicatorType.homework);
    }

    return indicators.map((type) => CalendarIndicator(type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);

    final leadingEmptyDays = firstDay.weekday - 1;
    final totalDays = daysInMonth();

    return Dialog(
      backgroundColor: const Color(0xFFFFFCF8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${monthName(displayedMonth.month)} '
                    '${displayedMonth.year}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final today = DateTime.now();
                    Navigator.pop(
                      context,
                      DateTime(today.year, today.month, today.day),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayedMonth = DateTime(
                        displayedMonth.year,
                        displayedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayedMonth = DateTime(
                        displayedMonth.year,
                        displayedMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(child: _CalendarWeekday('M')),
                Expanded(child: _CalendarWeekday('T')),
                Expanded(child: _CalendarWeekday('W')),
                Expanded(child: _CalendarWeekday('T')),
                Expanded(child: _CalendarWeekday('F')),
                Expanded(child: _CalendarWeekday('S')),
                Expanded(child: _CalendarWeekday('S')),
              ],
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingEmptyDays + totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) {
                  return const SizedBox();
                }

                final day = index - leadingEmptyDays + 1;

                final date = DateTime(
                  displayedMonth.year,
                  displayedMonth.month,
                  day,
                );

                final indicators = indicatorsFor(date);

                final isSelected =
                    widget.selectedDate.year == date.year &&
                    widget.selectedDate.month == date.month &&
                    widget.selectedDate.day == date.day;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A21)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF29231F),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: indicators.take(3).map((indicator) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : indicator.color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                _CalendarLegend(color: Color(0xFFFF7A21), text: 'Activity'),
                _CalendarLegend(color: Color(0xFF7661D8), text: 'Homework'),
                _CalendarLegend(color: Color(0xFF2A9D8F), text: 'Exam'),
                _CalendarLegend(color: Color(0xFF4C8FD9), text: 'Event'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarWeekday extends StatelessWidget {
  final String text;

  const _CalendarWeekday(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9A9089),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String text;

  const _CalendarLegend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF756B65)),
        ),
      ],
    );
  }
}
