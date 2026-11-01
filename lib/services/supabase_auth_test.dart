import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthTest {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> loginOwner() async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: 'owner@bag2school.local',
        password: 'Bag2School@2026',
      );

      final user = response.user;

      if (user == null) {
        return 'ERROR: Login berhasil tetapi user tidak ditemukan.';
      }

      return 'SUCCESS: Owner login berhasil. UID: ${user.id}';
    } catch (e) {
      return 'ERROR: Owner login gagal: $e';
    }
  }

  static String? currentUserId() {
    return _client.auth.currentUser?.id;
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}
