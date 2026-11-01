import 'package:supabase_flutter/supabase_flutter.dart';

import 'bagi_identity_controller.dart';

class BagiLocalAuthService {
  BagiLocalAuthService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const String _testPassword = String.fromEnvironment(
    'BAG2SCHOOL_TEST_PASSWORD',
  );

  static bool get isConfigured => _testPassword.isNotEmpty;

  static Future<bool> signIn({required String email}) async {
    if (!isConfigured) {
      return false;
    }

    try {
      BagiIdentityController.clear();

      await _client.auth.signInWithPassword(
        email: email,
        password: _testPassword,
      );

      final loaded = await BagiIdentityController.load();

      print(
        '[BagiAuth] email=$email '
        'uid=${_client.auth.currentUser?.id} '
        'profile=${BagiIdentityController.displayName} '
        'title=${BagiIdentityController.parentTitle} '
        'loaded=$loaded',
      );

      return loaded;
    } catch (_) {
      BagiIdentityController.clear();
      return false;
    }
  }

  static Future<void> signOut() async {
    BagiIdentityController.clear();

    try {
      await _client.auth.signOut();
    } catch (_) {
      // Keep local identity cleared even if sign-out fails.
    }
  }

  static String? get currentUserId => _client.auth.currentUser?.id;

  static String? get currentEmail => _client.auth.currentUser?.email;
}
