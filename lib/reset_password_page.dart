import 'package:flutter/material.dart';

import 'services/bagi_auth_service.dart';

/// Shown after the parent opens the recovery link from their email.
///
/// The link has already been exchanged for a session by the deep link handler,
/// so this page only sets the new password.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);

  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _password.text;
    final confirm = _confirm.text;

    // Matches the sign-up rule: at least 8 characters.
    if (password.length < 8) {
      setState(
        () => _error =
            'Your password needs at least 8 characters to keep your '
            'Bag2School account safe.',
      );
      return;
    }

    if (password != confirm) {
      setState(() => _error = 'The two passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final success = await BagiAuthService.updatePassword(password: password);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _saving = false;
        _error = 'Bagi could not save this password. Please try again.';
      });
      return;
    }

    // Sign out so the parent signs in fresh with the new password.
    await BagiAuthService.signOut();

    if (!mounted) return;

    setState(() => _saving = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Password updated 🎉',
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
        content: const Text(
          'Please sign in again with your new password.',
          style: TextStyle(color: _muted, height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: _orange),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Set new password',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
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
                  const Text(
                    'Choose a new password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick something you will remember, then confirm it below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      helperText: 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFB3261E),
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save new password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
