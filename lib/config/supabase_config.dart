import 'package:flutter/foundation.dart';

/// Supabase connection settings.
///
/// ### Release builds need a hosted project
///
/// Store builds must talk to an HTTPS project, so `SUPABASE_URL` is required:
///
/// ```sh
/// flutter build appbundle --release \
///   --dart-define=SUPABASE_URL=https://<project>.supabase.co
/// ```
///
/// Without it, [url] throws instead of silently pointing at `127.0.0.1`.
///
/// ### Local development (default, no flag needed)
///
/// Android reaches the laptop through the `adb reverse` tunnel:
///
/// ```sh
/// adb reverse tcp:54321 tcp:54321
/// flutter run
/// ```
///
/// The tunnel survives hot reload, but not unplugging the cable or rebooting
/// the phone; `tool\ensure_tunnel.ps1` recreates it.
///
/// ### Android over Wi-Fi (no cable)
///
/// Pass the laptop LAN address from `ipconfig`:
///
/// ```sh
/// flutter run --dart-define=SUPABASE_URL=http://192.168.40.101:54321
/// ```
///
/// Both devices must share the network, with VPN off.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _urlOverride = String.fromEnvironment('SUPABASE_URL');

  /// Loopback address of the local Supabase stack.
  static const String _loopbackHost = '127.0.0.1';

  /// LAN address of this development machine (iOS and documented example).
  ///
  /// Refresh it from `ipconfig` whenever the laptop changes network.
  static const String _lanHost = '192.168.40.101';

  static const int _port = 54321;

  /// Public key of the hosted project, passed at build time:
  ///
  /// ```sh
  /// --dart-define=SUPABASE_KEY=sb_publishable_...
  /// ```
  static const String _keyOverride = String.fromEnvironment('SUPABASE_KEY');

  /// Key of the local development stack.
  static const String _localPublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  static String get publishableKey =>
      _keyOverride.isNotEmpty ? _keyOverride : _localPublishableKey;

  static String get url {
    if (_urlOverride.isNotEmpty) {
      return _urlOverride;
    }

    if (kReleaseMode) {
      throw StateError(
        'SUPABASE_URL is required for release builds. Rebuild with '
        '--dart-define=SUPABASE_URL=https://<project>.supabase.co',
      );
    }

    if (kIsWeb) {
      return 'http://$_loopbackHost:$_port';
    }

    return switch (defaultTargetPlatform) {
      // Phones and emulators reach the laptop through the adb reverse tunnel.
      TargetPlatform.android => 'http://$_loopbackHost:$_port',
      TargetPlatform.iOS => 'http://$_lanHost:$_port',
      _ => 'http://$_loopbackHost:$_port',
    };
  }
}
