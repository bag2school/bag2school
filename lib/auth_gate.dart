import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'choose_family_page.dart';
import 'login_page.dart';
import 'data/store.dart';
import 'family_waiting_room_page.dart';
import 'services/bagi_family_service.dart';

class AuthGate extends StatefulWidget {
  final Widget authenticatedChild;

  const AuthGate({super.key, required this.authenticatedChild});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasFamily = false;
  bool _hasPendingJoinRequest = false;
  String? _checkedUserId;
  bool _invitationPromptShown = false;

  Future<void> _showFamilyJoinedDialog({
    required String familyName,
    required String role,
  }) async {
    if (!mounted) return;

    final roleName = switch (role) {
      'parent_guardian' => 'Parent / Guardian',
      'parentGuardian' => 'Parent / Guardian',
      'parent' => 'Parent / Guardian',
      'caregiver' => 'Caregiver',
      _ => role,
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Family Joined!'),
          content: Text('You have joined $familyName as $roleName.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Go to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    debugPrint('AUTH GATE CHECK | user: ${user?.id}');

    if (user == null) {
      if (!mounted) return;

      final pendingInvitationToken = Bag2SchoolStore.pendingInvitationToken;

      if (pendingInvitationToken != null &&
          pendingInvitationToken.isNotEmpty &&
          !_invitationPromptShown) {
        _invitationPromptShown = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('You\'ve Been Invited!'),
                content: const Text(
                  'You have been invited to join a family. '
                  'Please sign in or create an account to continue.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Continue'),
                  ),
                ],
              );
            },
          );
        });
      }

      setState(() {
        _loading = false;
        _hasFamily = false;
        _hasPendingJoinRequest = false;
        _checkedUserId = null;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final pendingInvitationToken = Bag2SchoolStore.pendingInvitationToken;

    if (pendingInvitationToken != null && pendingInvitationToken.isNotEmpty) {
      debugPrint('[AuthGate] Pending invitation token found');

      final result = await BagiFamilyService.consumeFamilyInvitationLink(
        token: pendingInvitationToken,
      );

      Bag2SchoolStore.pendingInvitationToken = null;

      debugPrint('[AuthGate] Invitation consume result: $result');

      if (result['success'] == true) {
        await Bag2SchoolStore.loadSupabaseFamily();

        final familyName = Bag2SchoolStore.currentFamilyName ?? 'your family';

        final role = result['role']?.toString() ?? '';

        if (!mounted) return;

        await _showFamilyJoinedDialog(familyName: familyName, role: role);

        if (!mounted) return;

        setState(() {
          _loading = false;
          _hasFamily = true;
          _hasPendingJoinRequest = false;
          _checkedUserId = user.id;
        });

        return;
      }

      debugPrint(
        '[AuthGate] Invitation was not consumed: '
        '${result['reason']}',
      );
    }

    bool hasFamily = false;
    bool hasPendingJoinRequest = false;

    try {
      hasFamily = await Bag2SchoolStore.loadSupabaseFamily();

      debugPrint('AUTH GATE FAMILY CHECK | hasFamily: $hasFamily');

      // Jika belum menjadi anggota family, cek apakah
      // user sedang menunggu approval dari Family Owner.
      if (!hasFamily) {
        final pendingRequest =
            await BagiFamilyService.getPendingFamilyJoinRequest();

        hasPendingJoinRequest = pendingRequest != null;

        debugPrint(
          'AUTH GATE PENDING REQUEST | '
          'hasPending: $hasPendingJoinRequest',
        );
      }
    } catch (e) {
      debugPrint('AUTH GATE FAMILY CHECK ERROR: $e');

      hasFamily = false;
      hasPendingJoinRequest = false;
    }

    if (!mounted) return;

    debugPrint(
      '[AuthGate] Family check: hasFamily=$hasFamily, pending=$hasPendingJoinRequest',
    );

    setState(() {
      _loading = false;
      _hasFamily = hasFamily;
      _hasPendingJoinRequest = hasPendingJoinRequest;
      _checkedUserId = user.id;
    });

    // Both devices stay signed in; the parent is simply told once.
    if (Bag2SchoolStore.otherDeviceSignIn) {
      Bag2SchoolStore.otherDeviceSignIn = false;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Signed in on another device'),
            content: const Text(
              'This account was just used to sign in on another device. '
              'Both devices stay signed in — if that was not you, change your '
              'password in Settings.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      });
    }
  }

  /// Cross-fades between Login, the waiting room and Home instead of cutting.
  Widget _withTransition(BuildContext context, Widget child, String key) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: <Widget>[...previous, if (current != null) current],
      ),
      transitionBuilder: (widget, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.995, end: 1).animate(animation),
          child: widget,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        debugPrint(
          'AUTH GATE BUILD | '
          'event: ${snapshot.data?.event} | '
          'session: ${session != null} | '
          'loading: $_loading | '
          'hasFamily: $_hasFamily',
        );

        if (session == null) {
          _checkedUserId = null;

          if (_loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              setState(() {
                _loading = false;
                _hasFamily = false;
              });
            });
          }

          return _withTransition(context, const LoginPage(), 'login');
        }

        if (_checkedUserId != session.user.id && !_loading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkCurrentUser();
          });
        }

        if (_loading) {
          return _withTransition(
            context,
            const Scaffold(
              backgroundColor: Color(0xFFFFFCF8),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A21)),
              ),
            ),
            'loading',
          );
        }

        if (!_hasFamily && _hasPendingJoinRequest) {
          return _withTransition(
            context,
            FamilyWaitingRoomPage(
              onFamilyJoined: () async {
                await _checkCurrentUser();
              },
            ),
            'waiting-room',
          );
        }

        if (!_hasFamily) {
          return _withTransition(
            context,
            ChooseFamilyPage(
              onFamilyCreated: () async {
                await _checkCurrentUser();
              },
              onFamilyJoined: () async {
                debugPrint('[AuthGate] onFamilyJoined CALLBACK START');

                await _checkCurrentUser();

                debugPrint('[AuthGate] onFamilyJoined CALLBACK END');
              },
            ),
            'choose-family',
          );
        }

        return _withTransition(context, widget.authenticatedChild, 'home');
      },
    );
  }
}
