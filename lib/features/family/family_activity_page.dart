import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/family_models.dart';
import '../../models/child_profile.dart';

// Family activity inbox. Extracted from lib/main.dart.

class FamilyActivityPage extends StatefulWidget {
  const FamilyActivityPage({super.key});

  @override
  State<FamilyActivityPage> createState() => _FamilyActivityPageState();
}

class _FamilyActivityPageState extends State<FamilyActivityPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);

  String _filter = 'All';

  String _actorName(String memberId) {
    final index = Bag2SchoolStore.familyMembers.indexWhere(
      (member) => member.id == memberId,
    );
    return index >= 0
        ? Bag2SchoolStore.familyMembers[index].displayName
        : 'Family member';
  }

  String _featureLabel(LocalPermissionFeature feature) =>
      LocalAuthorization.featureLabel(feature);

  /// Sticky-looking date heading for one day of family activity.
  Widget _dayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    final difference = today.difference(target).inDays;

    final String label;
    if (difference == 0) {
      label = 'Today';
    } else if (difference == 1) {
      label = 'Yesterday';
    } else {
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
      label = '${day.day} ${months[day.month - 1]} ${day.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8, left: 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: .8,
          fontWeight: FontWeight.w900,
          color: _muted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyId = Bag2SchoolStore.currentFamilyId;
    final all =
        Bag2SchoolStore.familyActivities
            .where(
              (activity) =>
                  currentFamilyId != null &&
                  activity.familyId == currentFamilyId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final filtered = _filter == 'All'
        ? all
        : all
              .where(
                (activity) =>
                    (activity.category.isNotEmpty
                        ? activity.category
                        : _featureLabel(activity.feature)) ==
                    _filter,
              )
              .toList();

    // Grouped by day, newest first, so opening the page lands on today.
    final rows = <Object>[];
    final groups = <DateTime, List<LocalFamilyActivity>>{};

    for (final activity in filtered) {
      final day = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      groups.putIfAbsent(day, () => <LocalFamilyActivity>[]).add(activity);
    }

    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final day in days) {
      rows.add(day);
      rows.addAll(groups[day]!);
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Activity',
          style: TextStyle(color: _orange, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                for (final filter in const [
                  'All',
                  'Schedule',
                  'Homework',
                  'Preparation',
                  'Exam',
                  'Family',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      selectedColor: const Color(0xFFFFE2CF),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No family activity yet.\nChanges made by family members will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, height: 1.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];

                      if (row is DateTime) {
                        return _dayHeader(row);
                      }

                      final activity = row as LocalFamilyActivity;
                      final actor = activity.actorName.isNotEmpty
                          ? activity.actorName
                          : _actorName(activity.actorMemberId);
                      final child = Bag2SchoolStore.childProfiles
                          .where((entry) => entry.id == activity.childId)
                          .cast<ChildProfile?>()
                          .firstWhere(
                            (entry) => entry != null,
                            orElse: () => null,
                          );
                      final time =
                          '${activity.createdAt.day}/${activity.createdAt.month} '
                          '${activity.createdAt.hour.toString().padLeft(2, '0')}:'
                          '${activity.createdAt.minute.toString().padLeft(2, '0')}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: activity.action == 'Deleted'
                                  ? const Color(0xFFFFE3E3)
                                  : const Color(0xFFFFEBDD),
                              child: Icon(
                                activity.action == 'Added'
                                    ? Icons.add_rounded
                                    : activity.action == 'Edited'
                                    ? Icons.edit_outlined
                                    : Icons.delete_outline_rounded,
                                size: 19,
                                color: activity.action == 'Deleted'
                                    ? const Color(0xFFC95757)
                                    : _orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activity.category == 'Family'
                                        ? actor
                                        : '$actor · ' +
                                              (child?.name ?? 'Child'),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activity.message,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
