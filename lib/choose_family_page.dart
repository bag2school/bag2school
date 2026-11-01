import 'package:flutter/material.dart';

import 'family_waiting_room_page.dart';
import 'create_family_page.dart';
import 'login_page.dart';

class ChooseFamilyPage extends StatelessWidget {
  final Future<void> Function()? onFamilyCreated;
  final Future<void> Function()? onFamilyJoined;

  const ChooseFamilyPage({
    super.key,
    this.onFamilyCreated,
    this.onFamilyJoined,
  });

  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

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
                  const SizedBox(height: 32),

                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 64,
                    color: _orange,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Welcome to Bag2School!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Your account is ready! Now let’s get you connected with your family.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 36),

                  _ChoiceCard(
                    icon: Icons.family_restroom_rounded,
                    title: 'Create a Family',
                    description: 'Start a new family space and organize school life together.',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateFamilyPage(
                            onFamilyCreated: onFamilyCreated,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _ChoiceCard(
                    icon: Icons.group_add_rounded,
                    title: 'Join a Family',
                    description: 'Connect with your family using an invitation or invitation code.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FamilyWaitingRoomPage(
                            onFamilyJoined: () async {
                              debugPrint('[ChooseFamily] onFamilyJoined START');

                              if (onFamilyJoined != null) {
                                await onFamilyJoined!();
                              }

                              debugPrint(
                                '[ChooseFamily] onFamilyJoined AFTER CALLBACK',
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
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

                  const SizedBox(height: 8),

                  const Text(
                    'You can always invite and manage family members later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 13),
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

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  static const Color _orange = Color(0xFFFF7A21);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFE1CF)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: _orange, size: 30),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: _orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
