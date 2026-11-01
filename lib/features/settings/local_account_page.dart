import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/family_models.dart';
import '../../widgets/app_notification.dart';
import '../../bagi_identity_settings_page.dart';
import '../../login_page.dart';
import '../../services/bagi_auth_service.dart';
import '../../services/bagi_family_service.dart';
import '../../utils/controllers.dart';

// Account screen reached from Settings.

class LocalAccountPage extends StatefulWidget {
  const LocalAccountPage({super.key});

  @override
  State<LocalAccountPage> createState() => _LocalAccountPageState();
}

class _LocalAccountPageState extends State<LocalAccountPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? validationMessage;
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                onChanged: (_) =>
                    setDialogState(() => validationMessage = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                onChanged: (_) =>
                    setDialogState(() => validationMessage = null),
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  validationMessage!,
                  style: const TextStyle(color: Color(0xFFB55252)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (passwordController.text.length < 6 ||
                    passwordController.text != confirmController.text) {
                  setDialogState(() {
                    validationMessage = passwordController.text.length < 6
                        ? 'Password must be at least 6 characters.'
                        : 'The passwords do not match.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, passwordController.text);
              },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
    if (!mounted || password == null) return;

    final success = await BagiAuthService.updatePassword(password: password);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(success ? 'Password updated' : 'Password not updated'),
        content: Text(
          success ? 'Your password was changed successfully.' : 'Could not update the password. Please sign in again and retry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmationController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final typed =
              confirmationController.text.trim().toUpperCase() == 'DELETE';

          return AlertDialog(
            title: const Text('Delete your account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your account and its data will be removed for good. If other '
                  'people are in your family, ownership passes to one of them. '
                  'If you are the only one, the family and its children go too.',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Type DELETE below so we know it is really you.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmationController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC95757),
                ),
                onPressed: typed
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Delete account'),
              ),
            ],
          );
        },
      ),
    );

    // The dialog is still animating out, so let it detach first.
    Future<void>.delayed(
      const Duration(milliseconds: 450),
      confirmationController.dispose,
    );

    if (!mounted || confirmed != true) return;

    final success = await BagiFamilyService.deleteOwnAccount();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bagi could not delete the account just now. Please try '
            'again in a moment, or email bag2school.project@gmail.com.',
          ),
        ),
      );
      return;
    }

    await Bag2SchoolStore.signOutLocal();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account deleted'),
        content: const Text(
          'All done — your account and its data are gone. Bagi will miss you, '
          'and you are welcome back any time.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editAccount() async {
    final account = Bag2SchoolStore.currentAccount;
    if (account == null) return;

    final nameController = TextEditingController(text: account.displayName);
    final emailController = TextEditingController(text: account.email);

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text(
          'My Account',
          style: TextStyle(color: _orange, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 10),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC95757),
                ),
                onPressed: () => Navigator.pop(dialogContext, <String, String>{
                  'action': 'change_password',
                }),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Change password'),
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
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              Navigator.pop(dialogContext, {'name': name, 'email': email});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeControllersAfterRoute([nameController, emailController]);
    });

    if (!mounted || result == null) return;
    if (result['action'] == 'change_password') {
      await _changePassword();
      return;
    }
    if (result['action'] == 'delete_account') {
      await _deleteAccount();
      return;
    }

    setState(() {
      Bag2SchoolStore.updateCurrentAccount(
        displayName: result['name'],
        email: result['email'],
      );

      final currentMember = Bag2SchoolStore.familyMemberForCurrentAccount();

      if (currentMember != null) {
        final memberIndex = Bag2SchoolStore.familyMembers.indexWhere(
          (member) => member.id == currentMember.id,
        );

        if (memberIndex >= 0) {
          Bag2SchoolStore.familyMembers[memberIndex] = Bag2SchoolStore
              .familyMembers[memberIndex]
              .copyWith(displayName: result['name']);
        }
      }
    });

    showAppNotification(
      context,
      title: 'Profile updated',
      message: 'Your profile has been updated successfully.',
      icon: Icons.person_outline_rounded,
    );
  }

  Future<void> _openBagiIdentitySettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BagiIdentitySettingsPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _showLocalSignIn() async {
    final available = Bag2SchoolStore.localAccounts;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                'Local Test Accounts',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
            ...available.map(
              (account) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBDD),
                  child: Icon(Icons.person_outline_rounded, color: _orange),
                ),
                title: Text(
                  account.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(account.email),
                trailing: account.id == Bag2SchoolStore.currentAccountId
                    ? const Icon(Icons.check_circle_rounded, color: _orange)
                    : null,
                onTap: () => Navigator.pop(sheetContext, account.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final success = await Bag2SchoolStore.signInLocal(selected);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign in to this test account.'),
        ),
      );
      return;
    }

    setState(() {});
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

  Widget _accessSummary(String childId) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    if (member == null) {
      return const SizedBox.shrink();
    }

    final child = Bag2SchoolStore.childProfiles.firstWhere(
      (entry) => entry.id == childId,
      orElse: () => Bag2SchoolStore.childProfiles.first,
    );
    final grant = Bag2SchoolStore.currentGrantForChild(childId);

    final isOwner = member.role == FamilyMemberRole.owner;

    final rows = <(String, bool, bool)>[
      (
        'Schedule',
        isOwner ? true : (grant?.viewSchedule ?? false),
        isOwner ? true : (grant?.editSchedule ?? false),
      ),
      (
        'Homework',
        isOwner ? true : (grant?.viewHomework ?? false),
        isOwner ? true : (grant?.editHomework ?? false),
      ),
      (
        'Preparation',
        isOwner ? true : (grant?.viewPreparation ?? false),
        isOwner ? true : (grant?.editPreparation ?? false),
      ),
      (
        'Exam',
        isOwner ? true : (grant?.viewExam ?? false),
        isOwner ? true : (grant?.editExam ?? false),
      ),
    ];

    final visibleRows = rows.where((row) => row.$2).toList();

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Access · ${child.name}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${member.displayName} · ${_roleLabel(member.role)}',
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
          const SizedBox(height: 12),
          if (visibleRows.isEmpty)
            const Text(
              'No access granted for this child.',
              style: TextStyle(
                fontSize: 11.5,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...visibleRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Color(0xFF55A56B),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'View',
                      style: TextStyle(fontSize: 10.5, color: _muted),
                    ),
                    const SizedBox(width: 13),
                    Icon(
                      row.$3 ? Icons.edit_rounded : Icons.lock_outline_rounded,
                      size: 16,
                      color: row.$3 ? _orange : _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      row.$3 ? 'Edit' : 'View only',
                      style: const TextStyle(fontSize: 10.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = Bag2SchoolStore.currentAccount;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(color: _orange, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBDD),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, size: 42, color: _orange),
                ),
                const SizedBox(height: 12),
                Text(
                  account?.displayName ?? 'Not signed in',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account?.email ?? 'No local account selected',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 16),
                if (account != null)
                  OutlinedButton.icon(
                    onPressed: _editAccount,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: const BorderSide(color: Color(0xFFFFC18F)),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _showLocalSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign in'),
                  ),
              ],
            ),
          ),
          if (account != null && Bag2SchoolStore.childProfiles.isNotEmpty)
            _accessSummary(Bag2SchoolStore.activeChildId),
          const SizedBox(height: 18),
          if (account != null)
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.logout_rounded, color: _orange),
              title: const Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Local test session only'),
              onTap: () async {
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.logout_rounded, color: _orange, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Sign out?',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Are you sure you want to sign out of Bag2School?',
                        style: TextStyle(height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign out'),
                        ),
                      ],
                    );
                  },
                );

                if (!mounted || shouldSignOut != true) return;

                await Bag2SchoolStore.signOutLocal();

                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            )
          else
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.login_rounded, color: _orange),
              title: const Text(
                'Local test sign in',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Choose a local account for testing'),
              onTap: _showLocalSignIn,
            ),

          // Account deletion lives here only, below Sign out, so there is a
          // single place to find it (and a single place the app store reviews).
          if (account != null) ...[
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFC95757),
              ),
              title: const Text(
                'Delete account',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC95757),
                ),
              ),
              subtitle: const Text(
                'Permanently removes your account and its data',
              ),
              onTap: _deleteAccount,
            ),
          ],
        ],
      ),
    );
  }
}
