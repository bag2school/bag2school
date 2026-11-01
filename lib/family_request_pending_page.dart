import 'package:flutter/material.dart';

class FamilyRequestPendingPage extends StatelessWidget {
  final String? familyName;

  const FamilyRequestPendingPage({super.key, this.familyName});

  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  @override
  Widget build(BuildContext context) {
    final familyText = familyName?.trim().isNotEmpty == true
        ? 'Your request to join $familyName has been sent.'
        : 'Your request to join the family has been sent.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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
                    const SizedBox(height: 24),

                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE8D8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 54,
                          color: _orange,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'You’re almost in!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      familyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFFE1CF)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 32,
                            color: _orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Waiting for approval',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The family owner will review your request. '
                            'Once approved, you’ll be able to join the family and access Bag2School together.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5EE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _orange,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can safely close the app. '
                              'Your request will remain pending.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          // Status check will be connected to Supabase next.
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Check Status'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        // Cancel request flow will be added later.
                      },
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          color: Color(0xFFD94B4B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
