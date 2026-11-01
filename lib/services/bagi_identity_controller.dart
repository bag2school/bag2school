import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'bagi_profile_service.dart';

class BagiIdentityController {
  BagiIdentityController._();

  static BagiProfile? _profile;

  static BagiProfile? get profile => _profile;

  static String get parentTitle {
    final value = _profile?.bagiTitle.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return '';
  }

  static String get displayName {
    final value = _profile?.displayName.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Family Owner';
  }

  static String get gender {
    final value = _profile?.gender?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'unknown';
  }

  static String get language {
    return _profile?.language ?? 'en';
  }

  static bool get isLoaded => _profile != null;

  static Future<bool> load() async {
    try {
      debugPrint('[IDENTITY CONTROLLER] 1. Starting load');

      final user = Supabase.instance.client.auth.currentUser;

      debugPrint('[IDENTITY CONTROLLER] 2. User exists: ${user != null}');

      if (user == null) {
        debugPrint('[IDENTITY CONTROLLER] No user - clearing profile');

        _profile = null;

        return false;
      }

      debugPrint('[IDENTITY CONTROLLER] 3. User ID: ${user.id}');

      debugPrint('[IDENTITY CONTROLLER] 4. BEFORE loadCurrentProfile');

      final profile = await BagiProfileService.loadCurrentProfile();

      debugPrint('[IDENTITY CONTROLLER] 5. AFTER loadCurrentProfile');

      _profile = profile;

      debugPrint('[IDENTITY CONTROLLER] 6. Profile exists: ${profile != null}');

      return profile != null;
    } catch (error, stackTrace) {
      debugPrint('[IDENTITY CONTROLLER] ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      _profile = null;

      return false;
    }
  }

  static Future<bool> saveIdentity({
    required String? gender,
    required String? preferredTitle,
  }) async {
    try {
      final profile = await BagiProfileService.updateIdentity(
        gender: gender,
        preferredTitle: preferredTitle,
      );

      if (profile == null) {
        return false;
      }

      _profile = profile;

      return true;
    } catch (_) {
      return false;
    }
  }

  static void clear() {
    _profile = null;
  }

  /// Names that must never be used to address the account, because they are
  /// placeholders the database writes when no real name is known yet.
  static const Set<String> _placeholderNames = <String>{
    'family owner',
    'family member',
    'bag2school family',
    'bag2school user',
    'unknown',
  };

  static String resolveAddressName({
    String? accountName,
    Iterable<String> preferredNames = const <String>[],
    Iterable<String> childNames = const <String>[],
    String fallbackName = 'there',
  }) {
    final childNamesByKey = childNames
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();

    final usedNames = <String>{};

    // The title the account picked for Bagi wins, then the account's own
    // names, then the cached profile, and only then the family role.
    for (final candidate in <String?>[
      _profile?.bagiTitle,
      ...preferredNames,
      accountName,
      _profile?.displayName,
    ]) {
      final name = candidate?.trim() ?? '';
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (_placeholderNames.contains(key)) continue;
      if (childNamesByKey.contains(key)) continue;
      if (!usedNames.add(key)) continue;

      return name;
    }

    final fallback = fallbackName.trim();
    return fallback.isEmpty ? 'there' : fallback;
  }

  static String personalize(
    String message, {
    String? accountName,
    Iterable<String> preferredNames = const <String>[],
    Iterable<String> childNames = const <String>[],
    String fallbackName = 'there',
  }) {
    final name = resolveAddressName(
      accountName: accountName,
      preferredNames: preferredNames,
      childNames: childNames,
      fallbackName: fallbackName,
    );

    return message.replaceAll('{parent}', name);
  }

  static String morningGreeting({required String childName}) {
    return 'Good morning, $parentTitle! '
        "Let's get $childName ready for a great day. 😊";
  }

  static String afternoonGreeting({required String childName}) {
    return 'Good afternoon, $parentTitle! '
        "Let's see how $childName is doing today. 😊";
  }

  static String eveningGreeting({required String childName}) {
    return 'Good evening, $parentTitle! '
        "Let's get $childName ready for tomorrow. 🌙";
  }

  static String nightGreeting({required String childName}) {
    return 'Good night, $parentTitle! '
        '$childName can rest once tomorrow is ready. 🌙';
  }
}
