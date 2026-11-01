import 'bagi_session_bridge.dart';

import 'package:flutter/foundation.dart';

class BagiIdentityBootstrap {
  BagiIdentityBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[IDENTITY] Already initialized');
      return;
    }

    try {
      debugPrint('[IDENTITY] 1. BEFORE SessionBridge.refresh');

      await BagiSessionBridge.refresh();

      debugPrint('[IDENTITY] 2. AFTER SessionBridge.refresh');
    } catch (e, stackTrace) {
      debugPrint('[IDENTITY] ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _initialized = true;
      debugPrint('[IDENTITY] 3. Initialized finished');
    }
  }

  static Future<void> refresh() async {
    try {
      await BagiSessionBridge.refresh();
    } finally {
      _initialized = true;
    }
  }

  static void clear() {
    BagiSessionBridge.clear();
    _initialized = false;
  }
}
