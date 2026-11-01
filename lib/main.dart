import 'config/supabase_config.dart';
import 'services/bagi_app_bootstrap.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import 'services/bagi_auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/reminder_content.dart';
import 'services/reminder_service.dart';
import 'theme/bag2school_tokens.dart';
import 'theme/page_transitions.dart';
import 'data/store.dart';
import 'features/home/home_page.dart';
import 'reset_password_page.dart';
import 'auth_gate.dart';

import 'package:flutter/services.dart';

/// Lets the notification tap return to the first route, whatever was open.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Tapping the daily reminder always lands on Home (or Login when signed out,
/// which AuthGate decides on the first route).
void goToHomeFromNotification() {
  final navigator = rootNavigatorKey.currentState;

  if (navigator == null) return;

  navigator.popUntil((route) => route.isFirst);
  debugPrint('[Reminder] Notification tapped, returned to Home');
}

/// Recovery link received before the first frame was ready.
Uri? _pendingRecoveryUri;

/// Exchanges the recovery link for a session and opens the new password page.
Future<void> handlePasswordRecoveryLink(Uri uri) async {
  final restored = await BagiAuthService.completePasswordRecovery(uri);

  if (!restored) {
    debugPrint('[Recovery] The link could not be used');
    return;
  }

  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  await navigator.push(
    MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
  );
}

/// Turns "riandi.pratama@mail.com" into "Riandi Pratama" so the signed-in
/// account still gets a friendly name when no display name was ever set.
StreamSubscription<Uri>? _invitationLinkSubscription;
final AppLifecycleListener _schoolDataLifecycleListener = AppLifecycleListener(
  onPause: Bag2SchoolStore.persistActiveChildSchoolData,
  onDetach: Bag2SchoolStore.persistActiveChildSchoolData,
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A framework assertion otherwise fills the screen with red code. Show a
  // readable panel instead, keeping the raw message in debug builds.
  ErrorWidget.builder = (details) => _BagiErrorScreen(details: details);

  debugPrint('[BOOT] 1. Flutter initialized');

  // Printed on every start so a wrong host is obvious in the logs.
  debugPrint('[BOOT] Supabase URL: ${SupabaseConfig.url}');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );

  debugPrint('[BOOT] 2. Supabase initialized');

  // Local notifications; a no-op on web.
  await DailyReminder.initialize(onTap: goToHomeFromNotification);

  debugPrint('[BOOT] 3. BEFORE BagiAppBootstrap');

  await BagiAppBootstrap.initialize();
  await Bag2SchoolStore.restoreLocalFamilyActivity();

  debugPrint('[BOOT] 4. AFTER BagiAppBootstrap');

  debugPrint('[BOOT] 5. BEFORE restoreSupabaseSession');

  await Bag2SchoolStore.restoreSupabaseSession();

  debugPrint('[BOOT] 6. AFTER restoreSupabaseSession');

  if (Bag2SchoolStore.isSignedIn) {
    Bag2SchoolStore.otherDeviceSignIn =
        await BagiAuthService.detectSignInOnAnotherDevice();
  }

  if (Bag2SchoolStore.isSignedIn) {
    debugPrint('[BOOT] 7. BEFORE loadSupabaseFamily');

    await Bag2SchoolStore.loadSupabaseFamily();

    await Bag2SchoolStore.restoreActiveChildSchoolData();

    debugPrint('[BOOT] 8. AFTER loadSupabaseFamily');
  }

  debugPrint('[BOOT] 9. BEFORE runApp');
  _schoolDataLifecycleListener;

  final webUri = Uri.base;
  final webToken = webUri.queryParameters['token'];

  if (webToken != null && webToken.isNotEmpty) {
    Bag2SchoolStore.pendingInvitationToken = webToken;

    debugPrint('[Invitation Link] Web token received: $webToken');
  }

  final appLinks = AppLinks();

  try {
    final initialUri = await appLinks.getInitialLink();

    if (initialUri != null &&
        initialUri.scheme == 'bag2school' &&
        initialUri.host == 'join-family') {
      final token = initialUri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        Bag2SchoolStore.pendingInvitationToken = token;
        debugPrint('[Invitation Link] Initial token received: $token');
      }
    }

    // The recovery link is handled after the first frame, when a navigator
    // exists, so the Set new password page can be pushed.
    if (initialUri != null &&
        initialUri.scheme == 'bag2school' &&
        initialUri.host == 'reset-password') {
      _pendingRecoveryUri = initialUri;
    }

    // Google sign-in returns here; the session is restored on this cold start.
    if (initialUri != null &&
        initialUri.scheme == 'bag2school' &&
        initialUri.host == 'login-callback') {
      unawaited(BagiAuthService.completeGoogleSignIn(initialUri));
    }
  } catch (error) {
    debugPrint('[Invitation Link] Initial link error: $error');
  }

  _invitationLinkSubscription = appLinks.uriLinkStream.listen(
    (uri) async {
      if (uri.scheme != 'bag2school') return;

      if (uri.host == 'reset-password') {
        await handlePasswordRecoveryLink(uri);
        return;
      }

      // Google sign-in while the app is already open.
      if (uri.host == 'login-callback') {
        await BagiAuthService.completeGoogleSignIn(uri);
        return;
      }

      if (uri.host != 'join-family') return;

      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        Bag2SchoolStore.pendingInvitationToken = token;

        debugPrint('[Invitation Link] Runtime token received: $token');
      }
    },
    onError: (error) {
      debugPrint('[Invitation Link] Runtime link error: $error');
    },
  );

  runApp(const Bag2SchoolApp());

  // The store refreshes the reminder after every data change.
  Bag2SchoolStore.onDataPersisted = refreshDailyReminder;

  final pendingRecovery = _pendingRecoveryUri;
  if (pendingRecovery != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(handlePasswordRecoveryLink(pendingRecovery));
    });
  }

  // Keep the daily reminder text aligned with the saved schedule.
  unawaited(refreshDailyReminder());

  debugPrint('[BOOT] 10. AFTER runApp');
}

class _BagiErrorScreen extends StatelessWidget {
  const _BagiErrorScreen({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCF8),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.backpack_rounded,
                  size: 52,
                  color: Color(0xFFFF7A21),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bagi tripped on something',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF302722),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This part of the screen hit an unexpected error. Go back and '
                  'try again — your data is safe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF756B65),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 18),
                  SelectableText(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF8A7E76),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Bag2SchoolApp extends StatelessWidget {
  const Bag2SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bag2School',
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Bag2SchoolColors.warmPaper,
        colorScheme: ColorScheme.fromSeed(seedColor: Bag2SchoolColors.orange),

        // Soft fade + lift between pages instead of the default zoom.
        pageTransitionsTheme: softPageTransitionsTheme,

        // Give interactive controls a consistent tactile response.
        // This keeps the UI friendly without changing the existing layout.
        splashFactory: InkRipple.splashFactory,
        splashColor: const Color(0x26FF7A21),
        highlightColor: const Color(0x14FF7A21),
        hoverColor: const Color(0x0DFF7A21),
        focusColor: const Color(0x14FF7A21),

        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x2EFF7A21);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x14FF7A21);
              }
              return null;
            }),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x22FF7A21);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x0FFF7A21);
              }
              return null;
            }),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x22FF7A21);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x0FFF7A21);
              }
              return null;
            }),
          ),
        ),

        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x24FF7A21);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x12FF7A21);
              }
              return null;
            }),
          ),
        ),
      ),
      home: const AuthGate(authenticatedChild: HomePage()),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class Bag2SchoolSuccessNotification {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: .38),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * .82,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .16),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBDD),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFFFF7A21), size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B211B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF7A6D65),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .82, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================
// LOGO
// ============================================================
/// Settings switch for the single daily reminder.
// ============================================================
// BAGI
// ============================================================

class BagiSmallCharacter extends StatelessWidget {
  const BagiSmallCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('🎒', style: TextStyle(fontSize: 48));
  }
}

class BagiMiniCharacter extends StatelessWidget {
  const BagiMiniCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE7D2),
        shape: BoxShape.circle,
      ),
      child: const Center(child: Text('🎒', style: TextStyle(fontSize: 34))),
    );
  }
}

// ============================================================
// SCHEDULE
// ============================================================

// ============================================================
// SCHEDULE TIMELINE ITEM
// ============================================================

// ============================================================
// TODO ITEM
// ============================================================

// ============================================================
// HOMEWORK PAGE — V5
// ============================================================

// ============================================================
// PREPARATION PAGE
// ============================================================

// ============================================================
// PREPARATION CHECKLIST
// ============================================================

// ============================================================
// SCHOOL ACTIVITY FORM
// ============================================================

// ============================================================
// BAG2SCHOOL ACTIVITY STORE
// ============================================================

// ============================================================
// BAG2SCHOOL ACTIVITY STORE
// ============================================================

/// Let Flutter finish keyboard/focus cleanup before a dialog is
/// removed from the tree. This avoids the InheritedElement
/// `_dependents.isEmpty` assertion when a TextField is focused.
/// Disposes text controllers once the closing route animation has finished.
///
/// Disposing straight after `showModalBottomSheet` / `showDialog` returns
/// throws "A TextEditingController was used after being disposed", because the
/// route is still animating out and its fields still talk to the controller.
/// That first error cascades into inherited-widget and GlobalKey assertions.
/// Composes the daily reminder from tomorrow's saved data.
///
/// Covers every child in the family (the active one first) and rotates the
/// wording by day so the message does not feel repetitive.
/// Re-schedules the reminder after any change to settings or data.
// ============================================================
// PREPARATION DATA
// ============================================================
//
// Preparation is intentionally NOT an Activity.
// It belongs to an Activity through activityId and has its own
// date/completion state.

// ============================================================
// BAG2SCHOOL ACTIVITY FOUNDATION
// ============================================================
//
// This is the data foundation for Add Activity.
// It is intentionally not changing the visible UI yet.
//
// Activity -> Recurrence -> Conflict Detection
// The activity model feeds Schedule, Calendar, Preparation, and Bagi.
// Homework remains a separate task model.

// ============================================================
// BAG2SCHOOL MONTH CALENDAR
// ============================================================
