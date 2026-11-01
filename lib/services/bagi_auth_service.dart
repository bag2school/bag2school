import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bagi_identity_controller.dart';

enum SignUpResult {
  success,
  emailAlreadyRegistered,
  invalidEmail,
  weakPassword,
  rateLimited,
  confirmationRequired,
  timedOut,
  failed,
}

class SignUpOutcome {
  const SignUpOutcome(this.result, {this.message});

  final SignUpResult result;
  final String? message;
}

enum SignInResult {
  success,

  /// The server rejected the email and password pair. Supabase deliberately
  /// does not reveal which one is wrong, to avoid leaking registered emails.
  invalidCredentials,
  emailNotConfirmed,

  /// The server could not be reached at all: cable tunnel closed, wrong host,
  /// Supabase stopped, or no network.
  networkError,

  /// Signed in, but the profile row could not be loaded.
  profileUnavailable,

  failed,
}

class BagiAuthService {
  BagiAuthService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      BagiIdentityController.clear();

      debugPrint('========================================');
      debugPrint('[LOGIN] START');
      debugPrint('[LOGIN] EMAIL: ${email.trim()}');
      debugPrint('[LOGIN] SUPABASE URL: ${_client.rest.url}');
      debugPrint('========================================');

      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('[LOGIN] AUTH RESPONSE USER: ${response.user?.id}');
      debugPrint('[LOGIN] AUTH RESPONSE SESSION: ${response.session != null}');

      if (response.user == null) {
        debugPrint('[LOGIN] FAILED: USER IS NULL');
        return SignInResult.failed;
      }

      // Multiple devices may stay signed in: parents often use a phone and a
      // tablet. The previous behaviour revoked every other session here.
      await _rememberThisDeviceSignIn(response.user!);

      final loaded = await BagiIdentityController.load();

      debugPrint('[LOGIN] IDENTITY LOADED: $loaded');

      if (!loaded) {
        debugPrint('[LOGIN] FAILED: IDENTITY NOT LOADED');
        return SignInResult.profileUnavailable;
      }

      debugPrint('[LOGIN] SUCCESS');

      return SignInResult.success;
    } on AuthException catch (error, stackTrace) {
      BagiIdentityController.clear();

      debugPrint('========================================');
      debugPrint('[LOGIN] AUTH EXCEPTION');
      debugPrint('[LOGIN] MESSAGE: ${error.message}');
      debugPrint('[LOGIN] STATUS: ${error.statusCode}');
      debugPrint('[LOGIN] ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('========================================');

      final message = error.message.toLowerCase();

      if (_isNetworkFailure(error)) {
        return SignInResult.networkError;
      }

      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials')) {
        return SignInResult.invalidCredentials;
      }

      if (message.contains('email not confirmed')) {
        return SignInResult.emailNotConfirmed;
      }

      return SignInResult.failed;
    } catch (error, stackTrace) {
      BagiIdentityController.clear();

      debugPrint('========================================');
      debugPrint('[LOGIN] UNEXPECTED ERROR');
      debugPrint('[LOGIN] ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('========================================');

      return _isNetworkFailure(error)
          ? SignInResult.networkError
          : SignInResult.failed;
    }
  }

  /// True when the failure happened before the server could answer, rather
  /// than because the credentials were rejected.
  static bool _isNetworkFailure(Object error) {
    final text = error.toString().toLowerCase();

    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('failed host lookup') ||
        text.contains('connection reset') ||
        text.contains('timed out') ||
        text.contains('authretryablefetchexception');
  }

  static Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      BagiIdentityController.clear();

      final normalizedEmail = email.trim();
      final metadata = {
        'display_name': displayName.trim(),
        'preferred_title': displayName.trim(),
      };
      AuthResponse response;
      try {
        response = await _client.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: metadata,
        );
      } on AuthException catch (error) {
        if (!_isSignupTimeout(error)) rethrow;

        // Auth can commit the account and then time out while returning its
        // response. Re-authenticate to distinguish that case from a failed
        // insert, so the user is not told to create an already-created account.
        try {
          final signIn = await _client.auth.signInWithPassword(
            email: normalizedEmail,
            password: password,
          );
          if (signIn.user != null) {
            await BagiIdentityController.load();
            return const SignUpOutcome(SignUpResult.success);
          }
        } on AuthException catch (signInError) {
          final message = signInError.message.toLowerCase();
          if (message.contains('email not confirmed')) {
            return const SignUpOutcome(
              SignUpResult.failed,
              message: 'Your account was created. Please check your email to finish signing in.',
            );
          }
        } catch (signInError) {
          debugPrint(
            '[SIGNUP] Follow-up sign-in after timeout failed: $signInError',
          );
        }
        return const SignUpOutcome(
          SignUpResult.timedOut,
          message: 'This is taking a little longer than expected. Please try signing in with this email before creating the account again.',
        );
      }

      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        return const SignUpOutcome(SignUpResult.emailAlreadyRegistered);
      }

      if (response.user == null) {
        return const SignUpOutcome(
          SignUpResult.failed,
          message: 'Bagi couldn’t finish creating your account just yet. Please try again in a moment.',
        );
      }

      if (response.session == null) {
        return const SignUpOutcome(
          SignUpResult.confirmationRequired,
          message:
              'You are almost in! Tap the link we sent to your inbox, then sign '
              'in and Bagi will be waiting.',
        );
      }

      final profileLoaded = await BagiIdentityController.load();
      if (!profileLoaded) {
        debugPrint(
          '[SIGNUP] Account created, but profile could not be loaded yet.',
        );
      }

      return const SignUpOutcome(SignUpResult.success);
    } on AuthException catch (error, stackTrace) {
      BagiIdentityController.clear();
      debugPrint('[SIGNUP] Auth error: ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);

      final message = error.message.toLowerCase();
      final code = (error.code ?? '').toLowerCase();

      if (message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('already been registered') ||
          code == 'user_already_exists' ||
          code == 'email_exists') {
        return const SignUpOutcome(SignUpResult.emailAlreadyRegistered);
      }

      // Badly formed address, for example "name@" or "name.com".
      if (code == 'email_address_invalid' ||
          code == 'validation_failed' ||
          message.contains('invalid email') ||
          message.contains('unable to validate email') ||
          message.contains('email address is invalid')) {
        return const SignUpOutcome(
          SignUpResult.invalidEmail,
          message:
              'Hmm, that email looks unfinished. Check for a missing @ or '
              'domain, then give it another go.',
        );
      }

      if (code == 'weak_password' ||
          message.contains('password should be') ||
          message.contains('password is too short') ||
          message.contains('weak password')) {
        return const SignUpOutcome(
          SignUpResult.weakPassword,
          message: 'A little longer, please — 8 characters or more keeps your account '
              'safe.',
        );
      }

      // Supabase limits how many emails it sends per hour on the free plan.
      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          message.contains('rate limit') ||
          message.contains('too many requests') ||
          message.contains('email send rate')) {
        return const SignUpOutcome(
          SignUpResult.rateLimited,
          message:
              'We have sent a few emails already. Give it a minute, then try '
              'again — the queue clears quickly.',
        );
      }

      if (message.contains('email not confirmed')) {
        return const SignUpOutcome(
          SignUpResult.confirmationRequired,
          message:
              'This email is not confirmed yet. Open the link in your inbox, '
              'then sign in.',
        );
      }

      if (_isSignupTimeout(error)) {
        return const SignUpOutcome(
          SignUpResult.timedOut,
          message: 'This is taking a little longer than expected. Try signing in first in case your account was created. If you cannot sign in, please try again in a moment.',
        );
      }

      if (_isNetworkFailure(error)) {
        return const SignUpOutcome(
          SignUpResult.failed,
          message: 'Bag2School could not reach the server. Check your connection, then try again.',
        );
      }

      return SignUpOutcome(
        SignUpResult.failed,
        message: 'Bagi couldn’t create your account just yet. Please check your details and try again in a moment.',
      );
    } catch (error, stackTrace) {
      BagiIdentityController.clear();
      debugPrint('[SIGNUP] Unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_isNetworkFailure(error)) {
        return const SignUpOutcome(
          SignUpResult.failed,
          message: 'Bag2School could not reach the server. Check your connection, then try again.',
        );
      }

      return const SignUpOutcome(
        SignUpResult.failed,
        message: 'Bagi couldn’t finish creating your account just yet. Please try signing in first, then try again if needed.',
      );
    }
  }

  static bool _isSignupTimeout(AuthException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == '504' ||
        error.code == 'request_timeout' ||
        message.contains('deadline exceeded') ||
        message.contains('timed out') ||
        message.contains('timeout');
  }

  /// Opens Google's consent screen in the browser.
  ///
  /// The browser returns to `bag2school://login-callback`, which main.dart
  /// turns into a session. Returns false when the browser cannot be opened.
  static Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'bag2school://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return true;
    } on AuthException catch (error) {
      debugPrint('[OAUTH] Could not start Google sign-in: ${error.message}');
      return false;
    } catch (error) {
      debugPrint('[OAUTH] Could not start Google sign-in: $error');
      return false;
    }
  }

  /// Completes the Google redirect by turning its code into a session.
  static Future<bool> completeGoogleSignIn(Uri uri) async {
    try {
      await _client.auth.getSessionFromUrl(uri);
      return _client.auth.currentSession != null;
    } catch (error) {
      // A cold start may already have consumed the code during initialize.
      if (_client.auth.currentSession != null) return true;

      debugPrint('[OAUTH] Could not complete Google sign-in: $error');
      return false;
    }
  }

  /// Remembers when this device signed in, so a sign-in elsewhere can be
  /// recognised later and announced to the parent.
  static Future<void> _rememberThisDeviceSignIn(User user) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'bag2school_device_signin_${user.id}',
        user.lastSignInAt ?? DateTime.now().toIso8601String(),
      );
    } catch (error) {
      debugPrint('[LOGIN] Could not remember sign-in time: $error');
    }
  }

  /// True when the account signed in on another device after this one.
  ///
  /// The value is refreshed from the server, compared with what this device
  /// recorded, and then updated so the notice is shown only once.
  static Future<bool> detectSignInOnAnotherDevice() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final preferences = await SharedPreferences.getInstance();
      final key = 'bag2school_device_signin_${user.id}';
      final stored = preferences.getString(key);

      final fresh = await _client.auth.getUser();
      final serverStamp = fresh.user?.lastSignInAt;
      if (serverStamp == null) return false;

      final serverTime = DateTime.tryParse(serverStamp);

      if (stored == null || stored.isEmpty) {
        await preferences.setString(key, serverStamp);
        return false;
      }

      final storedTime = DateTime.tryParse(stored);
      if (serverTime == null || storedTime == null) return false;

      if (serverTime.isAfter(storedTime.add(const Duration(seconds: 30)))) {
        await preferences.setString(key, serverStamp);
        return true;
      }

      return false;
    } catch (error) {
      debugPrint('[LOGIN] Could not check device sign-in: $error');
      return false;
    }
  }

  /// Sends the password recovery email.
  ///
  /// Returns null when the request was accepted, or a human readable reason
  /// when it was not (bad address, rate limit, misconfigured redirect).
  static Future<String?> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'bag2school://reset-password',
      );
      return null;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final code = (error.code ?? '').toLowerCase();
      debugPrint('[RECOVERY] Failed: ${error.message} (${error.code})');

      if (code == 'over_email_send_rate_limit' ||
          message.contains('rate limit') ||
          message.contains('too many')) {
        return 'We have sent a few reset emails already. Wait a minute, then try '
            'again.';
      }

      if (code == 'email_address_invalid' ||
          message.contains('invalid email') ||
          message.contains('unable to validate email')) {
        return 'That email looks unfinished. Check for a missing @ or domain.';
      }

      if (message.contains('redirect') || code.contains('redirect')) {
        return 'This build is not allowed to reset passwords yet. '
            'Add bag2school://reset-password to the redirect URLs in Supabase.';
      }

      return 'Bagi could not send the email right now. ${error.message}';
    } catch (error) {
      debugPrint('[RECOVERY] Failed: $error');
      return 'Bagi could not reach the mail service. Check your connection and '
          'try once more.';
    }
  }

  /// Completes the recovery link by turning its tokens into a session.
  ///
  /// Supabase returns the tokens in the URI fragment, for example
  /// `bag2school://reset-password#access_token=…&refresh_token=…`.
  static Future<bool> completePasswordRecovery(Uri uri) async {
    try {
      final fragment = uri.fragment.isNotEmpty ? uri.fragment : uri.query;
      if (fragment.isEmpty) return false;

      final params = Uri.splitQueryString(fragment);
      final refreshToken = params['refresh_token'];
      final type = params['type'];

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[RECOVERY] Missing refresh token (type: $type)');
        return false;
      }

      final response = await _client.auth.setSession(refreshToken);

      if (response.session == null) {
        debugPrint('[RECOVERY] Session was not restored');
        return false;
      }

      return true;
    } catch (error) {
      debugPrint('[RECOVERY] Could not complete recovery: $error');
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

  static Future<bool> updatePassword({required String password}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      return true;
    } on AuthException catch (error) {
      debugPrint('[Account] Password update error: ${error.message}');
      return false;
    } catch (error) {
      debugPrint('[Account] Password update error: $error');
      return false;
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  static bool get isSignedIn => currentUser != null;

  static String? get currentUserId => currentUser?.id;

  static String? get currentEmail => currentUser?.email;
}
