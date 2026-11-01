import 'package:flutter/material.dart';

import 'services/bagi_auth_service.dart';
import 'signup_page.dart';
import 'auth_gate.dart';
import 'features/home/home_page.dart';
import 'theme/bag2school_tokens.dart';
import 'widgets/bagi_character.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _orangeSoft = Bag2SchoolColors.orangeSoft;
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset your password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the email you use for Bag2School. We will send a link to '
              'set a new password.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _orange),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    // The dialog is still animating out, so let it detach first.
    Future<void>.delayed(const Duration(milliseconds: 450), controller.dispose);

    if (!mounted || email == null) return;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final failure = await BagiAuthService.requestPasswordReset(email);

    if (!mounted) return;

    setState(() => _isLoading = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(failure == null ? 'Check your email 📧' : 'Email not sent'),
        content: Text(
          failure ??
              'If $email has an account, a link to set a new password is on '
                  'its way. Open it on this phone to continue.',
          style: const TextStyle(height: 1.4),
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

  /// Opens the Google consent screen; the deep link finishes the sign-in.
  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);

    final started = await BagiAuthService.signInWithGoogle();

    if (!mounted) return;

    if (!started) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google sign-in. Please try again.'),
        ),
      );
      return;
    }

    // The browser takes over. Stop the spinner when the user comes back
    // without finishing, so the form does not stay disabled.
    Future<void>.delayed(const Duration(seconds: 25), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await BagiAuthService.signIn(
      email: email,
      password: password,
    );
    debugPrint('LOGIN RESULT: $result');
    debugPrint(
      'LOGIN CURRENT SESSION: '
      '${Supabase.instance.client.auth.currentSession != null}',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result != SignInResult.success) {
      final String title;
      final String message;
      final IconData icon;

      switch (result) {
        case SignInResult.networkError:
          title = 'Bag2School can’t reach the server 📡';
          message =
              'Your password was not checked because the app could not connect '
              'to its server. Check the connection and try again. When testing '
              'on a phone, make sure the USB tunnel is running.';
          icon = Icons.cloud_off_rounded;
        case SignInResult.invalidCredentials:
          title = 'Email or password doesn’t match 🔒';
          message =
              'Please check your email and password, then try again. '
              'If you have not created an account yet, sign up instead.';
          icon = Icons.lock_outline_rounded;
        case SignInResult.emailNotConfirmed:
          title = 'Please confirm your email 📧';
          message =
              'Open the confirmation link we sent to your email, then sign in '
              'again.';
          icon = Icons.mark_email_unread_rounded;
        case SignInResult.profileUnavailable:
          title = 'Your account is not ready yet';
          message =
              'You are signed in, but your profile could not be loaded. Please '
              'try again in a moment.';
          icon = Icons.person_off_rounded;
        case SignInResult.failed:
        case SignInResult.success:
          title = 'Oops! We couldn’t sign you in';
          message = 'Please try again in a moment.';
          icon = Icons.sentiment_dissatisfied_rounded;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF7A21), size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(height: 1.45)),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A21),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ],
          );
        },
      );

      return;
    }

    // LOGIN BERHASIL
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthGate(authenticatedChild: HomePage()),
      ),
    );
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
                  const SizedBox(height: 12),

                  Center(
                    child: Semantics(
                      label: 'Bagi, your friendly school-day companion',
                      image: true,
                      child: SizedBox.square(
                        dimension: 124,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _orangeSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: BagiCharacter(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Bag2School',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'A little help for every school day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: _muted),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sign in to continue to your family dashboard.',
                    style: TextStyle(color: _muted, height: 1.4),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
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
                    onSubmitted: (_) => _isLoading ? null : _signIn(),
                  ),

                  const SizedBox(height: 6),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: _orange,
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signIn,
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
                              'Sign in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE8DCD2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE8DCD2))),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _continueWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF302722),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE0D5CC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New to Bag2School?',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final created = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpPage(),
                                      ),
                                    );

                                if (!context.mounted || created != true) return;

                                await showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(
                                            Icons.celebration_rounded,
                                            color: _orange,
                                            size: 30,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Welcome to Bag2School!',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: const Text(
                                        'Your account has been created successfully! 🎉\n\n'
                                        'Now, let’s create your family space and get ready for a fun school journey together!',
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

                                if (!context.mounted) return;

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthGate(
                                      authenticatedChild: HomePage(),
                                    ),
                                  ),
                                  (route) => false,
                                );
                              },
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Let’s make school life easier and more fun! ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
