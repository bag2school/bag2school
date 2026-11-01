import 'package:flutter/material.dart';

import '../../../data/store.dart';
import '../../../models/child_profile.dart';
import '../../../models/family_models.dart';
import '../../../theme/bag2school_tokens.dart';
import '../../../widgets/child_avatar.dart';

/// Bottom sheet for choosing which child the app is looking at.
///
/// Grouped by family and scrollable, so a household with many children never
/// overflows. Each row carries the child's avatar, name, grade and whether this
/// account may edit their plans.
class ChildSwitcherSheet extends StatefulWidget {
  const ChildSwitcherSheet({super.key, required this.initialChildId});

  final String? initialChildId;

  @override
  State<ChildSwitcherSheet> createState() => _ChildSwitcherSheetState();
}

class _ChildSwitcherSheetState extends State<ChildSwitcherSheet> {
  late String? _selectedId = widget.initialChildId;
  String _query = '';

  List<ChildProfile> get _children {
    final all = Bag2SchoolStore.childProfiles;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return all;

    return all
        .where(
          (child) =>
              child.name.toLowerCase().contains(query) ||
              child.grade.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Children this account can fully manage, versus the ones it can only read.
  (List<ChildProfile>, List<ChildProfile>) _splitByAccess(
    List<ChildProfile> children,
  ) {
    final editable = <ChildProfile>[];
    final viewOnly = <ChildProfile>[];

    for (final child in children) {
      final canEdit = LocalAuthorization.canEdit(
        LocalPermissionFeature.schedule,
        childId: child.id,
      );
      (canEdit ? editable : viewOnly).add(child);
    }

    return (editable, viewOnly);
  }

  @override
  Widget build(BuildContext context) {
    final familyName = Bag2SchoolStore.currentFamilyName?.trim();
    final children = _children;
    final (editable, viewOnly) = _splitByAccess(children);
    final total = Bag2SchoolStore.childProfiles.length;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.46;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Switch child',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Bag2SchoolColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total == 1
                  ? 'One child in this family'
                  : '$total children in ${familyName?.isNotEmpty == true ? familyName : 'this family'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Bag2SchoolColors.muted,
              ),
            ),
            const SizedBox(height: 12),

            // Search only when the list is long enough to need it.
            if (total > 5) ...[
              TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search a child',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: Bag2SchoolColors.peach,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: children.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No child matches that name.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Bag2SchoolColors.muted),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        if (editable.isNotEmpty) ...[
                          _GroupLabel(
                            label: 'Your family',
                            detail: familyName?.isNotEmpty == true
                                ? familyName!
                                : null,
                            count: editable.length,
                          ),
                          for (final child in editable)
                            _ChildRow(
                              child: child,
                              selected: child.id == _selectedId,
                              viewOnly: false,
                              onTap: () =>
                                  setState(() => _selectedId = child.id),
                            ),
                        ],
                        if (viewOnly.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _GroupLabel(
                            label: 'Shared with you',
                            detail: 'View only',
                            count: viewOnly.length,
                          ),
                          for (final child in viewOnly)
                            _ChildRow(
                              child: child,
                              selected: child.id == _selectedId,
                              viewOnly: true,
                              onTap: () =>
                                  setState(() => _selectedId = child.id),
                            ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _selectedId == null
                    ? null
                    : () => Navigator.pop(context, _selectedId),
                style: FilledButton.styleFrom(
                  backgroundColor: Bag2SchoolColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Use this profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({
    required this.label,
    required this.detail,
    required this.count,
  });

  final String label;
  final String? detail;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            size: 16,
            color: Bag2SchoolColors.orangeText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: Bag2SchoolColors.orangeText,
              ),
            ),
          ),
          if (detail != null)
            Flexible(
              child: Text(
                detail!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Bag2SchoolColors.muted,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Bag2SchoolColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.selected,
    required this.viewOnly,
    required this.onTap,
  });

  final ChildProfile child;
  final bool selected;
  final bool viewOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Bag2SchoolColors.orange
        : const Color(0x14000000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Bag2SchoolColors.orangeSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
            ),
            child: Row(
              children: [
                ChildAvatar(
                  avatarUrl: child.avatarUrl,
                  gender: child.gender,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Bag2SchoolColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        child.grade.trim().isEmpty
                            ? 'No grade yet'
                            : child.grade,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Bag2SchoolColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (viewOnly)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: 'View only',
                      color: Bag2SchoolColors.homework,
                    ),
                  ),
                if (selected)
                  const _Chip(
                    label: 'Active',
                    color: Bag2SchoolColors.orangeText,
                  )
                else
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: Color(0xFFC9BDB5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
