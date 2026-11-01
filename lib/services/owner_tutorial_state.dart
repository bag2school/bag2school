import 'package:shared_preferences/shared_preferences.dart';

class OwnerTutorialState {
  OwnerTutorialState._();

  static String _pendingKey(String userId) =>
      'bag2school_owner_tutorial_pending_$userId';
  static String _completedKey(String userId) =>
      'bag2school_owner_tutorial_completed_v2_$userId';

  static Future<void> markPending(String userId) async {
    if (userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pendingKey(userId), true);
    await preferences.remove(_completedKey(userId));
  }

  static Future<bool> shouldShow(String userId) async {
    if (userId.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_pendingKey(userId)) == true &&
        preferences.getBool(_completedKey(userId)) != true;
  }

  static Future<bool> isCompleted(String userId) async {
    if (userId.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_completedKey(userId)) == true;
  }

  static Future<void> markCompleted(String userId) async {
    if (userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey(userId), true);
    await preferences.remove(_pendingKey(userId));
  }
}
