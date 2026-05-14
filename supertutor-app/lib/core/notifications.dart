import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _dailyReminderId = 1001;

  /// Call once at app start (after permissions/load).
  static Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final localName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(_mapTimezone(localName)));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    }

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(init);
  }

  static String _mapTimezone(String name) {
    // Crude mapper; on Android we usually get "Asia/Tashkent" already.
    if (name.contains('/')) return name;
    return 'Asia/Tashkent';
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true, badge: true);
      return granted ?? false;
    }
    return true;
  }

  /// Schedule a daily 19:00 local-time reminder. Idempotent.
  static Future<void> scheduleDailyReminder() async {
    if (kIsWeb) return;
    final p = await SharedPreferences.getInstance();
    if (p.getBool('pref_notifications') == false) return;

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'Kunlik eslatma',
        channelDescription: 'Streak yo\'qotmaslik uchun har kungi eslatma',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        '🦉 SuperTutor sizni kutmoqda',
        'Bugungi darsingiz bor — streak yo\'qotmang!',
        when,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Exact-alarm permission missing on Android 13+; fall back gracefully.
      try {
        await _plugin.zonedSchedule(
          _dailyReminderId,
          '🦉 SuperTutor sizni kutmoqda',
          'Bugungi darsingiz bor — streak yo\'qotmang!',
          when,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  static Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);
  }
}
