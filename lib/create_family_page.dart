import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/store.dart';
import 'login_page.dart';
import 'services/bagi_family_service.dart';
import 'services/bagi_profile_service.dart';
import 'services/owner_tutorial_state.dart';

class CreateFamilyPage extends StatefulWidget {
  final Future<void> Function()? onFamilyCreated;
  final bool signOutOnCancel;

  const CreateFamilyPage({
    super.key,
    this.onFamilyCreated,
    this.signOutOnCancel = true,
  });

  @override
  State<CreateFamilyPage> createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  final _familyNameController = TextEditingController();

  String _displayName = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final profile = await BagiProfileService.loadCurrentProfile();

    if (!mounted) return;

    setState(() {
      _displayName = profile?.displayName.trim() ?? '';
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    final familyName = _familyNameController.text.trim();
    final displayName = _displayName.trim();
    final isFirstFamily = Bag2SchoolStore.familyOptions.isEmpty;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (familyName.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your family name and your name.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final familyId = await BagiFamilyService.createFamily(
      familyName: familyName,
      displayName: displayName,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (familyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create your family. Please try again.'),
        ),
      );
      return;
    }

    Bag2SchoolStore.currentFamilyId = familyId;
    Bag2SchoolStore.currentFamilyName = familyName.trim();
    if (isFirstFamily && userId != null) {
      await OwnerTutorialState.markPending(userId);
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Your family is ready!',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          content: const Text(
            'Great! Your Bag2School family has been created successfully. '
            'Let’s start organizing your school journey together!',
            style: TextStyle(color: _muted, height: 1.45),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Let’s go!'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (!mounted) return;

    Navigator.of(context).pop();

    if (widget.onFamilyCreated != null) {
      await widget.onFamilyCreated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  const Icon(
                    Icons.family_restroom_rounded,
                    size: 76,
                    color: _orange,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Let’s build your family space! ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Let’s get everything ready for a happier, easier school journey together!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: _muted, height: 1.5),
                  ),

                  const SizedBox(height: 36),

                  TextField(
                    controller: _familyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Family name',
                      hintText: 'e.g. The Smith Family',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: _muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'You’re creating this family as',
                                style: TextStyle(fontSize: 12, color: _muted),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _displayName.isEmpty
                                    ? 'Loading...'
                                    : _displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _createFamily,
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create my family',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final shouldSignOut = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: const Text(
                                    'Leave for now?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _ink,
                                    ),
                                  ),
                                  content: const Text(
                                    'Take your time — this page can wait. If '
                                    'you leave now, your family is not created '
                                    'yet, and you can finish it whenever you '
                                    'like.',
                                    style: TextStyle(
                                      color: _muted,
                                      height: 1.45,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                      child: const Text(
                                        'Stay here',
                                        style: TextStyle(
                                          color: _muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Yes, leave'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (!mounted || shouldSignOut != true) return;

                            if (widget.signOutOnCancel) {
                              await Supabase.instance.client.auth.signOut();

                              if (!mounted) return;

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                              return;
                            }

                            // Nothing to undo: simply go back to the previous
                            // screen instead of leaving the button dead.
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
