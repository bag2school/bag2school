import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../models/child_profile.dart';
import '../../models/family_models.dart';
import '../../services/bagi_family_service.dart';
import '../../services/family_access_defaults.dart';
import '../../create_family_page.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/bagi_character.dart';
import '../../widgets/bagi_dialog.dart';
import '../../widgets/bagi_tutorial_overlay.dart';

// Family members, roles, invitations and child access.
// Extracted from lib/main.dart (step 5b).

class FamilySettingsPage extends StatefulWidget {
  final bool tutorial;
  final int tutorialStep;

  const FamilySettingsPage({
    super.key,
    this.tutorial = false,
    this.tutorialStep = 16,
  });

  @override
  State<FamilySettingsPage> createState() => _FamilySettingsPageState();
}

class _FamilySettingsPageState extends State<FamilySettingsPage> {
  final GlobalKey _familyMembersTutorialKey = GlobalKey();
  final GlobalKey _familyInviteTutorialKey = GlobalKey();
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _purple = Color(0xFF7661D8);
  static const Color _cream = Color(0xFFFFFCF8);

  @override
  void initState() {
    super.initState();
    if (widget.tutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_runFamilyPageTutorial());
      });
    }
  }

  Future<void> _runFamilyPageTutorial() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final membersContext = _familyMembersTutorialKey.currentContext;
    if (membersContext != null) await Scrollable.ensureVisible(membersContext);
    if (!mounted) return;
    final membersAction = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _familyMembersTutorialKey,
      stepLabel: 'Step ${widget.tutorialStep} of ${widget.tutorialStep + 1}',
      title: 'Family members and roles',
      message: 'This page shows the active family and everyone’s role. Owners can rename the family and manage members; members can leave. If you belong to more than one family, use the family card at the top to switch.',
    );
    if (!mounted) return;
    if (membersAction == BagiTutorialAction.skip) {
      Navigator.of(context).pop(false);
      return;
    }

    final isOwner =
        Bag2SchoolStore.familyMemberForCurrentAccount()?.role ==
        FamilyMemberRole.owner;
    final inviteContext = isOwner
        ? _familyInviteTutorialKey.currentContext
        : _familyMembersTutorialKey.currentContext;
    if (inviteContext != null) await Scrollable.ensureVisible(inviteContext);
    if (!mounted) return;
    final inviteAction = await showBagiTutorialSpotlight(
      context: context,
      targetKey: isOwner ? _familyInviteTutorialKey : _familyMembersTutorialKey,
      stepLabel:
          'Step ${widget.tutorialStep + 1} of ${widget.tutorialStep + 1}',
      title: isOwner ? 'Invite your family' : 'Manage family access',
      message: isOwner
          ? 'Tap Add Family Member to invite someone by email or link. Pick Parent/Guardian or Caregiver, then say which children they can see. Grant Access lets you change it later.'
          : 'The Owner invites members by email or link, chooses their role, and manages child access with Grant Access. Ask the Owner if you need someone added.',
    );
    if (mounted) {
      Navigator.of(context).pop(inviteAction != BagiTutorialAction.skip);
    }
  }

  String _roleLabel(FamilyMemberRole role) {
    switch (role) {
      case FamilyMemberRole.owner:
        return 'Owner';
      case FamilyMemberRole.parentGuardian:
        return 'Parent / Guardian';
      case FamilyMemberRole.caregiver:
        return 'Caregiver';
      case FamilyMemberRole.child:
        return 'Child';
    }
  }

  String _accessLabel(ChildAccessMode mode) {
    switch (mode) {
      case ChildAccessMode.managed:
        return 'Managed';
      case ChildAccessMode.shared:
        return 'Shared';
      case ChildAccessMode.independent:
        return 'Independent';
    }
  }

  Future<void> _showMemberEditor({FamilyMember? member}) async {
    final nameController = TextEditingController(
      text: member?.displayName ?? '',
    );

    final emailController = TextEditingController();

    var selectedRole = member?.role ?? FamilyMemberRole.parentGuardian;

    final result = await showDialog<Map<String, Object>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            member == null ? 'Add Family Member' : 'Edit Family Member',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (member == null)
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Bag2School account email',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                )
              else
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

              const SizedBox(height: 14),

              DropdownButtonFormField<FamilyMemberRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: FamilyMemberRole.values
                    .where(
                      (role) =>
                          role != FamilyMemberRole.owner ||
                          member?.role == FamilyMemberRole.owner,
                    )
                    .map(
                      (role) => DropdownMenuItem<FamilyMemberRole>(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),

              if (member?.role == FamilyMemberRole.owner) ...[
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'The family has one Owner. Owner role cannot be assigned to another member.',
                    style: TextStyle(fontSize: 11, height: 1.3, color: _muted),
                  ),
                ),
              ],
            ],
          ),

          actions: [
            if (member != null && member.role != FamilyMemberRole.owner)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      backgroundColor: _cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: const Text(
                        'Delete family member?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      content: Text(
                        'Remove ${member.displayName} from the family?',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(confirmContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete Member'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && dialogContext.mounted) {
                    Navigator.pop(dialogContext, <String, Object>{
                      'delete': true,
                    });
                  }
                },
                child: const Text(
                  'Delete Member',
                  style: TextStyle(color: Color(0xFFD94B4B)),
                ),
              ),

            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                // ADD FAMILY MEMBER
                if (member == null) {
                  final email = emailController.text.trim();

                  if (email.isEmpty) {
                    return;
                  }

                  Navigator.pop(dialogContext, <String, Object>{
                    'email': email,
                    'role': selectedRole,
                  });

                  return;
                }

                // EDIT FAMILY MEMBER
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, <String, Object>{
                  'name': name,
                  'role': selectedRole,
                });
              },
              child: Text(member == null ? 'Invite' : 'Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    emailController.dispose();

    if (!mounted || result == null) {
      return;
    }

    // ============================================================
    // DELETE MEMBER
    // ============================================================

    if (result['delete'] == true && member != null) {
      // Logic delete lama tetap diproses di bawah function sebelumnya.
      // Untuk sementara kita hanya keluar agar struktur function aman.
      return;
    }

    // ============================================================
    // ADD FAMILY MEMBER → INVITATION FLOW
    // ============================================================

    if (member == null) {
      final email = result['email']?.toString().trim() ?? '';

      final role = result['role'] as FamilyMemberRole?;

      if (email.isEmpty || role == null) {
        return;
      }

      debugPrint('[Family Invitation] Looking for: $email');

      final profile = await BagiFamilyService.findProfileByEmail(email);

      if (!mounted) return;

      if (profile == null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFFFE7D2),
                    child: Icon(
                      Icons.person_search_rounded,
                      size: 34,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Account not found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We could not find a Bag2School account using:\n$email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        );

        return;
      }

      debugPrint('[Family Invitation] Profile found: ${profile['id']}');

      final displayName = profile['display_name']?.toString() ?? email;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE8F7EE),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 34,
                    color: Color(0xFF38A169),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Send family invitation?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$displayName will be invited as ${_roleLabel(role)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Send Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted || confirmed != true) {
        return;
      }

      final familyId = Bag2SchoolStore.currentFamilyId;

      if (familyId == null || familyId.isEmpty) {
        return;
      }

      final success = await BagiFamilyService.createFamilyInvitation(
        familyId: familyId,
        invitedProfileId: profile['id'].toString(),
        invitedEmail: email,
        role: role == FamilyMemberRole.parentGuardian
            ? 'parent_guardian'
            : 'caregiver',
      );

      if (!mounted) return;

      if (success) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFE8F7EE),
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      size: 34,
                      color: Color(0xFF38A169),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Invitation sent!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An invitation has been sent to $displayName.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Great!'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFFFE7D2),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 34,
                      color: _orange,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We could not send the invitation. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.4, color: _muted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Close'),
              ),
            ],
          ),
        );
      }

      return;
    }

    // ============================================================
    // EDIT MEMBER
    // ============================================================

    if (member != null) {
      final name = result['name']?.toString();

      final role = result['role'] as FamilyMemberRole?;

      if (name == null || name.isEmpty || role == null) {
        return;
      }

      final index = Bag2SchoolStore.familyMembers.indexWhere(
        (entry) => entry.id == member.id,
      );

      if (index >= 0) {
        setState(() {
          Bag2SchoolStore.familyMembers[index] = member.copyWith(
            displayName: name,
            role: role,
          );
        });
      }
    }
  }

  Future<void> _showAddFamilyMemberMethodDialog() async {
    final method = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Add Family Member',
          style: TextStyle(fontWeight: FontWeight.w900, color: _orange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How would you like to invite them?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.link_rounded, color: _orange),
              title: const Text(
                'Invitation Link',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              subtitle: const Text('Create a link and choose their role'),
              onTap: () => Navigator.pop(dialogContext, 'link'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.pin_rounded, color: _orange),
              title: const Text(
                'Invitation Code',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              subtitle: const Text('Create a code to share'),
              onTap: () => Navigator.pop(dialogContext, 'code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || method == null) {
      return;
    }

    if (method == 'link') {
      await _showInvitationLinkDialog();
      return;
    }

    if (method == 'code') {
      await _showInvitationCodeDialog();
    }
  }

  /// Small Bagi chat used for confirmations such as "code copied".
  Future<void> _showBagiChatDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: BagiCharacter(mood: BagiMood.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: _muted, height: 1.45),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: _orange),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Asks the owner what the invited member may do with each child before the
  /// invitation code or link is created.
  Future<
    ({
      Map<String, MemberAccessLevel> access,
      Map<String, Set<String>> features,
    })?
  >
  _askMemberAccess(String role) async {
    final children = Bag2SchoolStore.childProfiles;
    final isCaregiver = role == 'caregiver';

    final selection = <String, MemberAccessLevel>{
      for (final child in children)
        child.id: isCaregiver ? MemberAccessLevel.view : MemberAccessLevel.full,
    };

    // Every feature is offered by default; the owner can untick any of them.
    const allFeatures = ['schedule', 'homework', 'preparation', 'exam'];
    final features = <String, Set<String>>{
      for (final child in children) child.id: {...allFeatures},
    };

    return showDialog<
      ({
        Map<String, MemberAccessLevel> access,
        Map<String, Set<String>> features,
      })
    >(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            'What can they see?',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCaregiver
                      ? 'Caregivers can look but not change plans. Pick what '
                            'they can see; they can ask you for edit access '
                            'later.'
                      : 'Pick what this person can see for each child. You can '
                            'change it any time with Grant / Manage Access.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 14),
                if (children.isEmpty)
                  const Text(
                    'Add a child first — then you can invite someone to help.',
                    style: TextStyle(fontSize: 12.5, color: _muted),
                  )
                else
                  ...children.map((child) {
                    final level = selection[child.id] ?? MemberAccessLevel.view;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<MemberAccessLevel>(
                            // Caregivers are view-only by design.
                            segments: <ButtonSegment<MemberAccessLevel>>[
                              const ButtonSegment(
                                value: MemberAccessLevel.none,
                                label: Text('None'),
                              ),
                              const ButtonSegment(
                                value: MemberAccessLevel.view,
                                label: Text('View'),
                              ),
                              if (!isCaregiver)
                                const ButtonSegment(
                                  value: MemberAccessLevel.full,
                                  label: Text('Full'),
                                ),
                            ],
                            selected: {level},
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            onSelectionChanged: (value) {
                              setDialogState(() {
                                selection[child.id] = value.first;
                                if (value.first == MemberAccessLevel.none) {
                                  features[child.id] = <String>{};
                                } else if ((features[child.id] ?? {}).isEmpty) {
                                  features[child.id] = {...allFeatures};
                                }
                              });
                            },
                          ),
                          if (level != MemberAccessLevel.none) ...[
                            const SizedBox(height: 8),
                            StatefulBuilder(
                              builder: (chipContext, setChipState) => Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  for (final feature in allFeatures)
                                    FilterChip(
                                      label: Text(switch (feature) {
                                        'schedule' => 'Schedule',
                                        'homework' => 'Homework',
                                        'preparation' => 'Preparation',
                                        _ => 'Exam',
                                      }),
                                      selected: (features[child.id] ?? {})
                                          .contains(feature),
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (value) {
                                        setChipState(() {
                                          final set = features[child.id] ??=
                                              <String>{};
                                          if (value) {
                                            set.add(feature);
                                          } else {
                                            set.remove(feature);
                                          }
                                          setDialogState(() {});
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                access: Map<String, MemberAccessLevel>.from(selection),
                features: {
                  for (final entry in features.entries)
                    entry.key: Set<String>.from(entry.value),
                },
              )),
              style: FilledButton.styleFrom(backgroundColor: _orange),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  /// Short summary shown with the invitation code, e.g. "Koko · Full".
  String _accessSummary(Map<String, MemberAccessLevel> access) {
    final labels = <String>[];

    for (final child in Bag2SchoolStore.childProfiles) {
      final level = access[child.id];
      if (level == null || level == MemberAccessLevel.none) continue;

      labels.add(
        '${child.name} · '
        '${level == MemberAccessLevel.full ? 'Full' : 'View'}',
      );
    }

    if (labels.isEmpty) {
      return 'No child access will be granted for this member.';
    }

    return 'Access prepared: ${labels.join(', ')}.';
  }

  Future<void> _showInvitationCodeDialog() async {
    final account = Bag2SchoolStore.currentAccount;

    if (account == null) {
      return;
    }

    // Ambil family aktif dari Supabase.
    final family = await BagiFamilyService.loadCurrentFamily(
      familyId: Bag2SchoolStore.currentFamilyId,
    );

    if (!mounted) return;

    if (family == null ||
        family['family'] == null ||
        family['family']['id'] == null) {
      showAppNotification(
        context,
        title: 'Family Not Found',
        message: 'We could not find your active family. Please try again.',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final familyData = Map<String, dynamic>.from(family['family'] as Map);

    final familyId = familyData['id'] as String;

    String? selectedRole = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Choose Family Member Role',
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose the role for the family member who will use this invitation code.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(
                Icons.family_restroom_rounded,
                color: _orange,
              ),
              title: const Text(
                'Parent / Guardian',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              subtitle: const Text(
                'Can manage family activities and settings.',
              ),
              onTap: () => Navigator.pop(dialogContext, 'parentGuardian'),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(
                Icons.volunteer_activism_rounded,
                color: _orange,
              ),
              title: const Text(
                'Caregiver',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              subtitle: const Text(
                'Can help care for and support the children.',
              ),
              onTap: () => Navigator.pop(dialogContext, 'caregiver'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || selectedRole == null) {
      return;
    }

    // Access comes before the code, so the member is never invited without it.
    final choice = await _askMemberAccess(selectedRole);

    if (!mounted || choice == null) {
      return;
    }

    final access = choice.access;

    await FamilyAccessDefaults.save(
      familyId: familyId,
      role: selectedRole,
      access: access,
    );
    await FamilyAccessDefaults.saveFeatures(
      familyId: familyId,
      role: selectedRole,
      features: choice.features,
    );

    final result = await BagiFamilyService.createFamilyInvitationCode(
      familyId: familyId,
      role: selectedRole,
    );

    debugPrint('[Invitation Code UI] RESULT: $result');

    if (!mounted) return;

    if (result == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Oops!',
            style: TextStyle(fontWeight: FontWeight.w900, color: _orange),
          ),
          content: const Text(
            'We could not create an invitation code right now. Please try again.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Okay'),
            ),
          ],
        ),
      );

      return;
    }

    final code = result['code']?.toString() ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Column(
          children: [
            Icon(Icons.celebration_rounded, size: 38, color: _orange),
            SizedBox(height: 10),
            Text(
              'Invitation Code Ready!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with your family member.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.4),
            ),

            const SizedBox(height: 10),

            Text(
              _accessSummary(access),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFC99F), width: 2),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w900,
                  color: _orange,
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 17, color: _muted),
                SizedBox(width: 6),
                Text(
                  'This code expires in 10 minutes',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));

              if (!dialogContext.mounted) return;

              await _showBagiChatDialog(
                title: 'Code copied! 📋',
                message:
                    'Paste it in your chat with the family member you are '
                    'inviting. The code stays valid for 10 minutes.',
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Code'),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInvitationLinkDialog() async {
    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose Member Role'),
          content: const Text(
            'Choose the role for the family member who will use this invitation link.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'parentGuardian'),
              child: const Text('Parent / Guardian'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'caregiver'),
              child: const Text('Caregiver'),
            ),
          ],
        );
      },
    );

    if (role == null) return;

    // Access comes before the link, so the member is never invited without it.
    final choice = await _askMemberAccess(role);

    if (!mounted || choice == null) return;

    final access = choice.access;

    final linkFamilyId = Bag2SchoolStore.currentFamilyId;

    if (linkFamilyId == null || linkFamilyId.isEmpty) return;

    await FamilyAccessDefaults.save(
      familyId: linkFamilyId,
      role: role,
      access: access,
    );
    await FamilyAccessDefaults.saveFeatures(
      familyId: linkFamilyId,
      role: role,
      features: choice.features,
    );

    final result = await BagiFamilyService.createFamilyInvitationLink(
      familyId: linkFamilyId,
      role: role,
    );

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create invitation link.')),
      );
      return;
    }

    final token = result['token']?.toString();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation link could not be created.')),
      );
      return;
    }

    // A real HTTPS page, not the local file path: the phone cannot open
    // `file:///...?token=` and friends cannot open it on their own phone.
    final link =
        'https://bag2school.github.io/bag2school/join.html?token=$token';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invitation Link Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this link with the family member. '
                'The link expires in 10 minutes and can only be used once.',
              ),
              const SizedBox(height: 16),
              SelectableText(link, style: const TextStyle(fontSize: 13)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));

                if (!dialogContext.mounted) return;

                await _showBagiChatDialog(
                  title: 'Link copied! 🔗',
                  message:
                      'Send it to the family member you are inviting. The link '
                      'works once and expires in 10 minutes.',
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Link'),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _grantAccess(
    ChildProfile child, {
    String? initialMemberId,
  }) async {
    final eligibleMembers = Bag2SchoolStore.familyMembers
        .where((member) => member.role != FamilyMemberRole.owner)
        .toList();

    if (eligibleMembers.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Family Member Yet'),
          content: const Text(
            'Add a Family Member first, then you can grant access to this child.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    FamilyMember selectedMember = eligibleMembers.firstWhere(
      (member) => member.id == initialMemberId,
      orElse: () => eligibleMembers.first,
    );
    var viewSchedule = false;
    var editSchedule = false;
    var viewHomework = false;
    var editHomework = false;
    var viewPreparation = false;
    var editPreparation = false;
    var viewExam = false;
    var editExam = false;

    var accessChanged = false;

    final existing = Bag2SchoolStore.accessGrantFor(
      child.id,
      selectedMember.id,
    );
    if (existing != null) {
      viewSchedule = existing.viewSchedule;
      editSchedule = existing.editSchedule;
      viewHomework = existing.viewHomework;
      editHomework = existing.editHomework;
      viewPreparation = existing.viewPreparation;
      editPreparation = existing.editPreparation;
      viewExam = existing.viewExam;
      editExam = existing.editExam;
    }

    final result = await showDialog<FamilyAccessGrant>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          title: Text(
            'Grant Access · ${child.name}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _orange),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FamilyMember>(
                  value: selectedMember,
                  decoration: const InputDecoration(
                    labelText: 'Family member',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: eligibleMembers
                      .map(
                        (member) => DropdownMenuItem<FamilyMember>(
                          value: member,
                          child: Text(member.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (member) {
                    if (member == null) return;
                    setDialogState(() {
                      selectedMember = member;
                      final saved = Bag2SchoolStore.accessGrantFor(
                        child.id,
                        member.id,
                      );
                      viewSchedule = saved?.viewSchedule ?? false;
                      editSchedule = saved?.editSchedule ?? false;
                      viewHomework = saved?.viewHomework ?? false;
                      editHomework = saved?.editHomework ?? false;
                      viewPreparation = saved?.viewPreparation ?? false;
                      editPreparation = saved?.editPreparation ?? false;
                      viewExam = saved?.viewExam ?? false;
                      editExam = saved?.editExam ?? false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What this member can access',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: viewSchedule,
                  activeColor: _orange,
                  title: const Text('View Schedule'),
                  onChanged: (value) =>
                      setDialogState(() => viewSchedule = value),
                ),
                SwitchListTile(
                  value: editSchedule,
                  activeColor: _orange,
                  title: const Text('Edit Schedule'),
                  onChanged: viewSchedule
                      ? (value) => setDialogState(() => editSchedule = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewHomework,
                  activeColor: _orange,
                  title: const Text('View Homework'),
                  onChanged: (value) =>
                      setDialogState(() => viewHomework = value),
                ),
                SwitchListTile(
                  value: editHomework,
                  activeColor: _orange,
                  title: const Text('Edit Homework'),
                  onChanged: viewHomework
                      ? (value) => setDialogState(() => editHomework = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewPreparation,
                  activeColor: _orange,
                  title: const Text('View Preparation'),
                  onChanged: (value) =>
                      setDialogState(() => viewPreparation = value),
                ),
                SwitchListTile(
                  value: editPreparation,
                  activeColor: _orange,
                  title: const Text('Edit Preparation'),
                  onChanged: viewPreparation
                      ? (value) => setDialogState(() => editPreparation = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewExam,
                  activeColor: _orange,
                  title: const Text('View Exam'),
                  onChanged: (value) => setDialogState(() => viewExam = value),
                ),
                SwitchListTile(
                  value: editExam,
                  activeColor: _orange,
                  title: const Text('Edit Exam'),
                  onChanged: viewExam
                      ? (value) => setDialogState(() => editExam = value)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            if (Bag2SchoolStore.accessGrantFor(child.id, selectedMember.id) !=
                null)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      backgroundColor: _cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: const Text(
                        'Remove access?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      content: Text(
                        'Remove ${selectedMember.displayName}’s access to ${child.name}? '
                        'They will no longer be able to use the permissions currently granted.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(confirmContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Remove Access'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && dialogContext.mounted) {
                    Bag2SchoolStore.removeAccessGrant(
                      child.id,
                      selectedMember.id,
                    );
                    accessChanged = true;
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text(
                  'Remove Access',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                FamilyAccessGrant(
                  memberId: selectedMember.id,
                  childId: child.id,
                  viewSchedule: viewSchedule,
                  editSchedule: editSchedule,
                  viewHomework: viewHomework,
                  editHomework: editHomework,
                  viewPreparation: viewPreparation,
                  editPreparation: editPreparation,
                  viewExam: viewExam,
                  editExam: editExam,
                ),
              ),
              child: Text(
                Bag2SchoolStore.accessGrantFor(child.id, selectedMember.id) ==
                        null
                    ? 'Grant Access'
                    : 'Save Access',
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        Bag2SchoolStore.saveAccessGrant(result);
      });

      showAppNotification(
        context,
        title: 'Access Granted',
        message: 'Access has been saved successfully.',
        icon: Icons.verified_user_rounded,
      );
    } else if (accessChanged) {
      setState(() {});
    }
  }

  Future<void> _editChildAccess(ChildProfile child) async {
    final current = Bag2SchoolStore.accessForChild(child.id);
    var mode = current.mode;
    var viewSchedule = current.parentViewSchedule;
    var viewHomework = current.parentViewHomework;
    var viewPreparation = current.parentViewPreparation;
    var viewExam = current.parentViewExam;

    final result = await showDialog<ChildAccessSettings>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          title: Text(
            '${child.name} Access',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _orange),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ChildAccessMode>(
                  value: mode,
                  decoration: const InputDecoration(
                    labelText: 'Access mode',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  items: ChildAccessMode.values
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry,
                          child: Text(_accessLabel(entry)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => mode = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (mode != ChildAccessMode.independent) ...[
                  SwitchListTile(
                    value: viewSchedule,
                    activeColor: _orange,
                    title: const Text('View Schedule'),
                    onChanged: (value) =>
                        setDialogState(() => viewSchedule = value),
                  ),
                  SwitchListTile(
                    value: viewHomework,
                    activeColor: _orange,
                    title: const Text('View Homework'),
                    onChanged: (value) =>
                        setDialogState(() => viewHomework = value),
                  ),
                  SwitchListTile(
                    value: viewPreparation,
                    activeColor: _orange,
                    title: const Text('View Preparation'),
                    onChanged: (value) =>
                        setDialogState(() => viewPreparation = value),
                  ),
                  SwitchListTile(
                    value: viewExam,
                    activeColor: _orange,
                    title: const Text('View Exam'),
                    onChanged: (value) =>
                        setDialogState(() => viewExam = value),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  mode == ChildAccessMode.managed
                      ? 'Parent or guardian manages the child profile. The child does not need a separate account.'
                      : mode == ChildAccessMode.shared
                      ? 'The child can have their own account while selected family access remains available.'
                      : 'The child manages their own account. Family access can be added later according to the family arrangement.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _muted,
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
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                ChildAccessSettings(
                  childId: child.id,
                  mode: mode,
                  parentViewSchedule: viewSchedule,
                  parentViewHomework: viewHomework,
                  parentViewPreparation: viewPreparation,
                  parentViewExam: viewExam,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      Bag2SchoolStore.updateChildAccess(result);
    });
  }

  Widget _memberCard(FamilyMember member, {required bool canManage}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: canManage && member.role != FamilyMemberRole.owner
            ? () => _showMemberEditor(member: member)
            : null,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEBDD),
          child: Icon(
            member.role == FamilyMemberRole.child
                ? Icons.child_care_rounded
                : Icons.person_outline_rounded,
            color: member.role == FamilyMemberRole.child ? _purple : _orange,
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        subtitle: Text(_roleLabel(member.role)),
        trailing: canManage && member.role != FamilyMemberRole.owner
            ? const Icon(Icons.edit_outlined, color: _muted, size: 20)
            : null,
      ),
    );
  }

  Widget _childAccessCard(ChildProfile child) {
    final settings = Bag2SchoolStore.accessForChild(child.id);
    final grants = Bag2SchoolStore.familyAccessGrants.values
        .where((grant) => grant.childId == child.id)
        .toList();

    String memberName(String memberId) {
      final index = Bag2SchoolStore.familyMembers.indexWhere(
        (entry) => entry.id == memberId,
      );
      return index >= 0
          ? Bag2SchoolStore.familyMembers[index].displayName
          : 'Family member';
    }

    String grantSummary(FamilyAccessGrant grant) {
      final parts = <String>[];
      if (grant.viewSchedule) {
        parts.add(grant.editSchedule ? 'Schedule edit' : 'Schedule view');
      }
      if (grant.viewHomework) {
        parts.add(grant.editHomework ? 'Homework edit' : 'Homework view');
      }
      if (grant.viewPreparation) {
        parts.add(
          grant.editPreparation ? 'Preparation edit' : 'Preparation view',
        );
      }
      if (grant.viewExam) {
        parts.add(grant.editExam ? 'Exam edit' : 'Exam view');
      }
      return parts.isEmpty ? 'No access' : parts.join(' · ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _editChildAccess(child),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFE7D2),
              child: Text('👦🏻'),
            ),
            title: Text(
              child.name,
              style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
            ),
            subtitle: Text('${child.grade} · ${_accessLabel(settings.mode)}'),
            trailing: const Icon(Icons.tune_rounded, color: _muted),
          ),
          if (grants.isNotEmpty) ...[
            const Divider(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Granted access',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 5),
            ...grants.map(
              (grant) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: _purple,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName(grant.memberId),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            grantSummary(grant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.2,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Manage access',
                      onPressed: () =>
                          _grantAccess(child, initialMemberId: grant.memberId),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _grantAccess(child),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(
                grants.isEmpty ? 'Grant Access' : 'Grant / Manage Access',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: Color(0xFFD8D0F8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFamilyFeedback(String title, String message) async {
    if (!mounted) return;

    await showBagiDialog<void>(
      context: context,
      title: title,
      message: message,
      primaryLabel: 'Got it',
    );
  }

  Future<void> _renameCurrentFamily() async {
    final familyId = Bag2SchoolStore.currentFamilyId;
    if (familyId == null || familyId.isEmpty) return;
    final controller = TextEditingController(
      text: Bag2SchoolStore.currentFamilyName ?? '',
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Family'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Family name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || newName == null || newName.trim().isEmpty) return;

    final normalizedName = newName.trim();
    final success = await BagiFamilyService.renameFamily(
      familyId: familyId,
      name: normalizedName,
    );
    if (!mounted) return;
    if (!success) {
      await _showFamilyFeedback(
        'Family not renamed',
        'Could not rename this family. Please try again.',
      );
      return;
    }

    final oldName = Bag2SchoolStore.currentFamilyName ?? 'Family';
    Bag2SchoolStore.currentFamilyName = normalizedName;
    Bag2SchoolStore.familyOptions = Bag2SchoolStore.familyOptions
        .map(
          (family) => family['id']?.toString() == familyId
              ? <String, dynamic>{...family, 'name': normalizedName}
              : family,
        )
        .toList();
    Bag2SchoolStore.recordFamilyManagementActivity(
      action: 'Edited',
      title: 'Family renamed',
      message: '$oldName was renamed to $normalizedName.',
      entityId: familyId,
    );
    setState(() {});
    await _showFamilyFeedback(
      'Family renamed',
      'The family name was updated to $normalizedName.',
    );
  }

  Future<void> _leaveCurrentFamily() async {
    final familyId = Bag2SchoolStore.currentFamilyId;
    if (familyId == null || familyId.isEmpty) return;
    final currentMember = Bag2SchoolStore.familyMemberForCurrentAccount();
    if (currentMember == null) return;

    String? newOwnerProfileId;
    if (currentMember.role == FamilyMemberRole.owner) {
      final otherMembers = Bag2SchoolStore.familyMembers
          .where(
            (member) =>
                member.id != currentMember.id &&
                member.accountId != null &&
                member.accountId!.isNotEmpty,
          )
          .toList();
      if (otherMembers.isEmpty) {
        await _showFamilyFeedback(
          'Cannot leave family',
          'Add another account to this family before leaving as Owner.',
        );
        return;
      }
      newOwnerProfileId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Transfer ownership'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Choose a family member to become Owner before you leave.',
                ),
                const SizedBox(height: 12),
                ...otherMembers.map(
                  (member) => ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(member.displayName),
                    subtitle: Text(
                      member.role == FamilyMemberRole.caregiver
                          ? 'Caregiver'
                          : 'Parent / Guardian',
                    ),
                    onTap: () => Navigator.pop(dialogContext, member.accountId),
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
          ],
        ),
      );
      if (newOwnerProfileId == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave this family?'),
          content: const Text(
            'You will lose access to this family and its children.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Leave family'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final familyName = Bag2SchoolStore.currentFamilyName ?? 'Family';
    final result = await BagiFamilyService.leaveFamily(
      familyId: familyId,
      newOwnerProfileId: newOwnerProfileId,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      await _showFamilyFeedback(
        'Could not leave family',
        'Please try again. If the problem continues, refresh the family and retry.',
      );
      return;
    }

    Bag2SchoolStore.recordFamilyManagementActivity(
      action: 'Left',
      title: 'Family member left',
      message: currentMember.displayName + ' left ' + familyName + '.',
      entityId: familyId,
    );
    final hasFamily = await Bag2SchoolStore.loadSupabaseFamily();
    if (!hasFamily) Bag2SchoolStore.familyMembers.clear();
    if (!mounted) return;
    setState(() {});
    await _showFamilyFeedback(
      'You left $familyName',
      'That is done. You can join or create a family whenever you like — Bagi will keep everything else exactly as it is.',
    );
  }

  Future<void> _showFamilySwitcher() async {
    final options = Bag2SchoolStore.familyOptions;

    if (options.length <= 1) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch Family',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose which family you want to manage.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: _muted),
                ),
                const SizedBox(height: 16),
                ...options.map((family) {
                  final familyId = family['id']?.toString() ?? '';
                  final familyName = family['name']?.toString() ?? 'Family';
                  final role = family['role']?.toString() ?? '';
                  final isActive = familyId == Bag2SchoolStore.currentFamilyId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE7D2),
                      child: Icon(Icons.home_rounded, color: _orange),
                    ),
                    title: Text(
                      familyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    subtitle: Text(
                      role == 'owner'
                          ? 'Owner'
                          : role == 'parent_guardian' ||
                                role == 'parentGuardian'
                          ? 'Parent / Guardian'
                          : role == 'caregiver'
                          ? 'Caregiver'
                          : role,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_circle_rounded, color: _orange)
                        : null,
                    onTap: isActive
                        ? null
                        : () async {
                            Bag2SchoolStore.currentFamilyId = familyId;

                            Navigator.of(sheetContext).pop();

                            final loaded =
                                await Bag2SchoolStore.loadSupabaseFamily();

                            if (!mounted) return;

                            if (loaded) {
                              setState(() {});

                              await showBagiDialog<void>(
                                context: context,
                                title: 'Welcome to $familyName',
                                message:
                                    'Bagi switched the family for you. '
                                    'Anything you add from now on belongs to '
                                    '$familyName.',
                                primaryLabel: 'Great',
                              );
                              return;
                            }

                            await showBagiDialog<void>(
                              context: context,
                              title: 'That family did not load',
                              message:
                                  'Bagi could not open $familyName just now. '
                                  'Check your connection and tap it once more.',
                              primaryLabel: 'OK',
                              mood: BagiMood.failed,
                            );
                          },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJoinFamilyDialog() async {
    final codeController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Join a Family',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          content: TextField(
            controller: codeController,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
            decoration: const InputDecoration(
              labelText: 'Please enter your invitation code',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();

                if (code.length != 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a 4-character invitation code.',
                      ),
                    ),
                  );
                  return;
                }

                final result =
                    await BagiFamilyService.validateFamilyInvitationCode(
                      code: code,
                    );

                if (!dialogContext.mounted) return;

                if (result['valid'] != true) {
                  String message;

                  switch (result['reason']?.toString()) {
                    case 'not_found':
                      message = 'This invitation code is not valid.';
                      break;

                    case 'expired':
                      message =
                          'This invitation code has expired. '
                          'Please ask the family owner for a new code.';
                      break;

                    default:
                      message =
                          'Unable to validate the invitation code. '
                          'Please try again.';
                  }

                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(message)));
                  return;
                }

                final joinResult =
                    await BagiFamilyService.joinFamilyWithInvitationCode(
                      code: code,
                    );

                if (!dialogContext.mounted) return;

                if (joinResult['success'] != true) {
                  String message;

                  switch (joinResult['reason']?.toString()) {
                    case 'already_member':
                      message = 'You are already a member of this family.';
                      break;

                    case 'not_authenticated':
                      message = 'Please sign in again and try once more.';
                      break;

                    default:
                      message = 'Unable to join this family. Please try again.';
                  }

                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(message)));
                  return;
                }

                Navigator.pop(dialogContext);

                if (!context.mounted) return;

                final loaded = await Bag2SchoolStore.loadSupabaseFamily();

                if (!mounted || !loaded) return;

                setState(() {});

                await showDialog<void>(
                  context: context,
                  builder: (successContext) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFFFFFCF8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: const Text(
                        'Family Joined!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      content: Text(
                        'You have successfully joined '
                        '${Bag2SchoolStore.currentFamilyName ?? 'this family'}.',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(successContext);
                          },
                          child: const Text("Let's go!"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    codeController.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final currentAccount = Bag2SchoolStore.currentAccount;
    final currentMember = Bag2SchoolStore.familyMemberForCurrentAccount();
    final currentRole = currentMember?.role;

    debugPrint('========================================');
    debugPrint('[Family] CURRENT USER: ${currentAccount?.email}');
    debugPrint('[Family] ACCOUNT MEMBER ID: ${currentAccount?.familyMemberId}');
    debugPrint('[Family] FAMILY MEMBER: ${currentMember?.displayName}');
    debugPrint('[Family] FAMILY MEMBER ID: ${currentMember?.id}');
    debugPrint('[Family] CURRENT ROLE: $currentRole');
    debugPrint('[Family] IS OWNER: ${currentRole == FamilyMemberRole.owner}');
    debugPrint('========================================');

    final isOwner = currentRole == FamilyMemberRole.owner;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family',
          style: TextStyle(color: _orange, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          if (Bag2SchoolStore.familyOptions.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: Bag2SchoolStore.familyOptions.length > 1
                  ? _showFamilySwitcher
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFE1C8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7D2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.home_rounded, color: _orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Family',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Bag2SchoolStore.currentFamilyName ?? 'Family',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (Bag2SchoolStore.familyOptions.length > 1)
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _muted,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          if (Bag2SchoolStore.currentFamilyId != null) ...[
            Row(
              children: [
                if (isOwner)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _renameCurrentFamily,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Rename Family'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _orange,
                        side: const BorderSide(color: Color(0xFFFFC18F)),
                      ),
                    ),
                  ),
                if (isOwner) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _leaveCurrentFamily,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Leave Family'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC95757),
                      side: const BorderSide(color: Color(0xFFF2C5C5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text(
            'Family Members',
            key: _familyMembersTutorialKey,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w900,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          ...Bag2SchoolStore.familyMembers.map(
            (member) => _memberCard(member, canManage: isOwner),
          ),
          if (isOwner)
            OutlinedButton.icon(
              key: _familyInviteTutorialKey,
              onPressed: () => _showAddFamilyMemberMethodDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Family Member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: const BorderSide(color: Color(0xFFFFC18F)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _showJoinFamilyDialog,
            icon: const Icon(Icons.group_rounded),
            label: const Text('Join a Family'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFC18F)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateFamilyPage(
                    signOutOnCancel: false,
                    onFamilyCreated: () async {
                      final loaded = await Bag2SchoolStore.loadSupabaseFamily();
                      if (mounted && loaded) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Create a Family'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFC18F)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (isOwner) ...[
            const Text(
              'Child Access',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w900,
                color: _muted,
              ),
            ),
            const SizedBox(height: 10),
            // One compact card that expands, so many children do not turn the
            // family page into a long scroll.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  leading: const Icon(
                    Icons.lock_person_rounded,
                    color: _orange,
                  ),
                  title: Text(
                    '${Bag2SchoolStore.childProfiles.length} '
                    '${Bag2SchoolStore.childProfiles.length == 1 ? 'child' : 'children'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  subtitle: Text(
                    '${Bag2SchoolStore.currentFamilyName ?? 'This family'} · '
                    'tap to manage who sees what',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: _muted),
                  ),
                  children: [
                    ...Bag2SchoolStore.childProfiles.map(_childAccessCard),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (isOwner)
            const Text(
              'Access mode is a family setting for now. Login, invitations and cloud permissions will be connected in the Account/Cloud phase.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: _muted),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Family member access is managed by the Family Owner.',
                style: TextStyle(fontSize: 11.5, height: 1.4, color: _muted),
              ),
            ),
        ],
      ),
    );
  }
}
