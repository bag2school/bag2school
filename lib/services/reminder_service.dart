import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// One daily reminder about tomorrow's school day.
///
/// Only one notification id is used, so scheduling again replaces the previous
/// reminder instead of stacking new ones. The text is composed by the caller
/// from the saved schedule; this class only handles permissions and timing.
class DailyReminder {
  DailyReminder._();

  static const String _enabledKey = 'bag2school_daily_reminder_enabled';
  static const String _hourKey = 'bag2school_daily_reminder_hour';
  static const String _minuteKey = 'bag2school_daily_reminder_minute';

  static const int defaultHour = 19;
  static const int defaultMinute = 0;

  static const int _notificationId = 1001;
  static const String _channelId = 'bag2school_daily_reminder';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// False on web, where scheduled local notifications are not supported.
  static bool get isSupported => !kIsWeb;

  static Future<void> initialize({VoidCallback? onTap}) async {
    if (!isSupported || _initialized) return;

    try {
      tz_data.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          onTap?.call();
        },
      );
      _initialized = true;
    } catch (error) {
      debugPrint('[Reminder] Could not initialise: $error');
    }
  }

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  static Future<int> reminderHour() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_hourKey) ?? defaultHour;
  }

  static Future<int> reminderMinute() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_minuteKey) ?? defaultMinute;
  }

  static Future<void> saveTime({required int hour, required int minute}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_hourKey, hour);
    await preferences.setInt(_minuteKey, minute);
  }

  static Future<void> saveEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }

  /// Asks for the Android 13+ notification permission.
  ///
  /// Returns true when notifications may be posted afterwards.
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;

    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return true;

    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Schedules the daily reminder, replacing any previous one.
  static Future<bool> schedule({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!isSupported) return false;

    await initialize();

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final canBeExact =
          await android?.canScheduleExactNotifications() ?? false;

      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily school reminder',
          channelDescription:
              'One friendly reminder about tomorrow’s school day.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: title,
        body: body,
        payload: 'home',
        scheduledDate: next,
        notificationDetails: details,
        androidScheduleMode: canBeExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[Reminder] Scheduled for $next');
      return true;
    } catch (error) {
      debugPrint('[Reminder] Could not schedule: $error');
      return false;
    }
  }

  static Future<void> cancel() async {
    if (!isSupported) return;

    await initialize();

    try {
      await _plugin.cancel(id: _notificationId);
    } catch (error) {
      debugPrint('[Reminder] Could not cancel: $error');
    }
  }

  /// Next occurrence of the reminder time, for display in Settings.
  static String describeTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
