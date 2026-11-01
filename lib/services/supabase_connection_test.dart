import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnectionTest {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> testConnection() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, display_name, language')
          .limit(1);

      return 'SUCCESS: Supabase connected. Rows: ${response.length}';
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
