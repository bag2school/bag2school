import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/bagi_family_service.dart';
import 'login_page.dart';

class FamilyWaitingRoomPage extends StatefulWidget {
  final Future<void> Function() onFamilyJoined;

  const FamilyWaitingRoomPage({super.key, required this.onFamilyJoined});

  @override
  State<FamilyWaitingRoomPage> createState() => _FamilyWaitingRoomPageState();
}

class _FamilyWaitingRoomPageState extends State<FamilyWaitingRoomPage> {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  Map<String, dynamic>? _pendingRequest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequest();
  }

  Future<void> _loadPendingRequest() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final request = await BagiFamilyService.getPendingFamilyJoinRequest();

    if (!mounted) return;

    setState(() {
      _pendingRequest = request;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingRequest != null) ...[
                    const SizedBox(height: 24),

                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8D8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 48,
                        color: _orange,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Waiting for approval',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Your request has been sent to the family owner. '
                      'Please wait for them to approve your request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEDE5DF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _orange,
                            size: 28,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Your family join request is pending.',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Back to Login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _orange,
                          side: const BorderSide(color: _orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),

                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8D8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 48,
                        color: _orange,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Ready to join a family?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'You can join your family using an invitation or an invitation code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _WaitingCard(
                      icon: Icons.mail_outline_rounded,
                      title: 'Waiting for an invitation?',
                      description: 'Ask your family owner to invite your Bag2School account.',
                    ),

                    const SizedBox(height: 14),

                    _WaitingCard(
                      icon: Icons.vpn_key_outlined,
                      title: 'Have an invitation code?',
                      description: 'Enter your family invitation code to request access.',
                      highlighted: true,
                      onTap: () {
                        _showInvitationCodeDialog(
                          context,
                          widget.onFamilyJoined,
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'When your family invitation is ready, it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showInvitationCodeDialog(
  BuildContext context,
  Future<void> Function() onFamilyJoined,
) {
  final codeController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFFFFFCF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Enter Invitation Code',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF302722),
          ),
        ),
        content: TextField(
          controller: codeController,
          maxLength: 4,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          // No keyboard suggestions: they used to insert an old code that the
          // user then could not delete.
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const <String>[],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
          decoration: const InputDecoration(counterText: ''),
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
              debugPrint('[Waiting Room] Continue invitation code pressed');
              final code = codeController.text.trim().toUpperCase();

              debugPrint(
                '[Waiting Room] Entered code: "$code" length=${code.length}',
              );

              if (code.length != 4) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pop in the 4 letters your family owner sent you.',
                    ),
                  ),
                );
                return;
              }

              debugPrint('[Waiting Room] Calling invitation validation...');

              final result =
                  await BagiFamilyService.validateFamilyInvitationCode(
                    code: code,
                  );

              debugPrint('[Waiting Room] Validation result: $result');

              if (!dialogContext.mounted) return;

              if (result['valid'] != true) {
                String message;

                switch (result['reason']?.toString()) {
                  case 'not_found':
                    message =
                        'That code is not active any more. Each code works '
                        'once and lasts 10 minutes — ask the family owner for '
                        'the current one.';
                    break;

                  case 'used':
                    message =
                        'Someone already used this code. Ask the family '
                        'owner for the fresh code shown in their app.';
                    break;

                  case 'expired':
                    message =
                        'This code has expired. Ask the family owner for the '
                        'new one — it only takes a moment.';
                    break;

                  default:
                    message = 'Unable to validate the invitation code. Please try again.';
                }

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text(message)));
                return;
              }

              final familyId = result['family_id']?.toString();
              final codeId = result['code_id']?.toString();

              if (familyId == null || codeId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invitation information is incomplete. Please try again.',
                    ),
                  ),
                );
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
                    message =
                        'Unable to send your join request. Please try again.';
                }

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text(message)));

                return;
              }

              Navigator.pop(dialogContext);

              if (!context.mounted) return;

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
                        color: Color(0xFF302722),
                      ),
                    ),
                    content: const Text(
                      'You have successfully joined your family. '
                      'Your family is ready to go!',
                      style: TextStyle(
                        color: Color(0xFF756B65),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(successContext);

                          if (!context.mounted) return;

                          await onFamilyJoined();

                          if (!context.mounted) return;

                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go to Home'),
                      ),
                    ],
                  );
                },
              );

              if (!context.mounted) return;

              await onFamilyJoined();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A21),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
}

class _WaitingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highlighted;
  final VoidCallback? onTap;

  const _WaitingCard({
    required this.icon,
    required this.title,
    required this.description,
    this.highlighted = false,
    this.onTap,
  });

  static const Color _orange = Color(0xFFFF7A21);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFFFFF5EE) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFFFC99F)
                  : const Color(0xFFFFE5D4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _orange, size: 25),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _orange,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
