import 'package:supabase_flutter/supabase_flutter.dart';

class BagiProfile {
  final String id;
  final String displayName;
  final String? gender;
  final String? preferredTitle;
  final String language;

  const BagiProfile({
    required this.id,
    required this.displayName,
    required this.language,
    this.gender,
    this.preferredTitle,
  });

  factory BagiProfile.fromMap(Map<String, dynamic> map) {
    return BagiProfile(
      id: map['id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      gender: map['gender']?.toString(),
      preferredTitle: map['preferred_title']?.toString(),
      language: map['language']?.toString() ?? 'en',
    );
  }

  String get bagiTitle {
    final value = preferredTitle?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return '';
  }
}

class BagiProfileService {
  BagiProfileService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<BagiProfile?> loadCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .select('id, display_name, language, gender, preferred_title')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return BagiProfile.fromMap(Map<String, dynamic>.from(row));
  }

  static Future<String> loadCurrentParentTitle() async {
    final profile = await loadCurrentProfile();

    return profile?.bagiTitle ?? '';
  }

  static Future<BagiProfile?> updateIdentity({
    String? gender,
    String? preferredTitle,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final updates = <String, dynamic>{
      'gender': gender,
      'preferred_title': preferredTitle,
    };

    final row = await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select('id, display_name, language, gender, preferred_title')
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return BagiProfile.fromMap(Map<String, dynamic>.from(row));
  }
}
