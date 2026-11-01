import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bagi_identity_controller.dart';

class BagiSessionBridge {
  BagiSessionBridge._();

  static Future<bool> refresh() async {
    debugPrint('[SESSION] 1. Starting refresh');

    final session = Supabase.instance.client.auth.currentSession;

    debugPrint('[SESSION] 2. Session exists: ${session != null}');

    if (session == null) {
      debugPrint('[SESSION] 3. No session, clearing identity');

      BagiIdentityController.clear();

      debugPrint('[SESSION] 4. Refresh finished - false');

      return false;
    }

    debugPrint('[SESSION] 5. BEFORE IdentityController.load');

    final result = await BagiIdentityController.load();

    debugPrint('[SESSION] 6. AFTER IdentityController.load: $result');

    return result;
  }

  static void clear() {
    BagiIdentityController.clear();
  }

  static bool get isAuthenticated {
    return Supabase.instance.client.auth.currentSession != null;
  }

  static String get parentTitle {
    return BagiIdentityController.parentTitle;
  }

  static String get displayName {
    return BagiIdentityController.displayName;
  }

  static String get gender {
    return BagiIdentityController.gender;
  }

  static String get language {
    return BagiIdentityController.language;
  }
}
