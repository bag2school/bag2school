import 'package:flutter/material.dart';

import 'widgets/bagi_character.dart';

import 'services/bagi_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showFriendlyMessage(
        title: 'Almost there!',
        message: 'Let’s fill in all the details first so Bagi can get everything ready for you.',
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      _showFriendlyMessage(
        title: 'Hmm, check your email!',
        message: 'That email address doesn’t look quite right. Please check it and try again.',
        icon: Icons.email_outlined,
      );
      return;
    }

    if (password.length < 8) {
      _showFriendlyMessage(
        title: 'Let’s make it stronger!',
        message: 'Your password needs at least 8 characters to keep your Bag2School account safe.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    if (password != confirmPassword) {
      _showFriendlyMessage(
        title: 'Almost there!',
        message:
            'Your passwords don’t match yet. Let’s make sure they’re the same.',
        icon: Icons.lock_reset_rounded,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final outcome = await BagiAuthService.signUp(
      email: email,
      password: password,
      displayName: name,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (outcome.result == SignUpResult.emailAlreadyRegistered) {
      _showFriendlyMessage(
        title: 'This account already exists',
        message:
            'This email is already registered. Please sign in, or reset the '
            'password if you forgot it.',
        icon: Icons.mark_email_read_rounded,
      );
      return;
    }

    if (outcome.result == SignUpResult.confirmationRequired) {
      _showFriendlyMessage(
        title: 'Confirm your email',
        message:
            outcome.message ??
            'Your account was created. Open the confirmation link in your '
                'inbox, then sign in.',
        icon: Icons.forward_to_inbox_rounded,
      );
      return;
    }

    if (outcome.result == SignUpResult.invalidEmail) {
      _showFriendlyMessage(
        title: 'Check the email address',
        message:
            outcome.message ??
            'That email address does not look complete. Check for a missing '
                '@ or domain.',
        icon: Icons.alternate_email_rounded,
      );
      return;
    }

    if (outcome.result == SignUpResult.weakPassword) {
      _showFriendlyMessage(
        title: 'Choose a stronger password',
        message:
            outcome.message ?? 'Use at least 8 characters for your password.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    if (outcome.result == SignUpResult.rateLimited) {
      _showFriendlyMessage(
        title: 'Just a moment',
        message:
            outcome.message ??
            'Too many emails were sent just now. Wait a minute, then try again.',
        icon: Icons.hourglass_bottom_rounded,
      );
      return;
    }

    if (outcome.result == SignUpResult.failed ||
        outcome.result == SignUpResult.timedOut) {
      _showFriendlyMessage(
        title: 'We couldn’t finish creating your account',
        message:
            outcome.message ??
            'Bagi couldn’t create your account just yet. Please try again.',
        icon: Icons.sentiment_dissatisfied_rounded,
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showFriendlyMessage({
    required String title,
    required String message,
    IconData icon = Icons.auto_awesome_rounded,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1E8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _orange, size: 36),
                ),

                const SizedBox(height: 18),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _muted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Create your account',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                  // This column stretches its children, so centre the mascot
                  // instead of letting it fill the full width.
                  const Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: BagiCharacter(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Welcome to Bag2School!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Let’s get your family’s school journey organized and ready for great days ahead.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: _muted, height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      hintText: 'What should we call you?',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _signUp(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signUp,
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
                              'Let’s get started!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
