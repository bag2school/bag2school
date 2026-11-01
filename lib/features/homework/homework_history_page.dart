import 'package:flutter/material.dart';

import '../../data/store.dart';

// Completed and overdue homework list.

class HomeworkHistoryPage extends StatelessWidget {
  const HomeworkHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    // History means: already completed, or still open but past its due date.
    final items = Bag2SchoolStore.homeworks.where((h) {
      final due = DateTime(h.dueDate.year, h.dueDate.month, h.dueDate.day);
      return h.completed || due.isBefore(today);
    }).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Homework History',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Completed and overdue homework will appear here. 😊',
                style: TextStyle(color: Color(0xFF756B65)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                '${items.length} item${items.length == 1 ? '' : 's'} · newest first',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF756B65),
                ),
              ),
            ),
          ...items.map((item) {
            final done = item.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      (done ? const Color(0xFF4C956C) : const Color(0xFFC97845))
                          .withOpacity(.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: done
                        ? const Color(0xFF4C956C)
                        : const Color(0xFFC97845),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.task,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${done ? 'Completed' : 'Overdue'} · ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: done
                                ? const Color(0xFF4C956C)
                                : const Color(0xFFC97845),
                            fontWeight: FontWeight.w700,
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
    );
  }
}
