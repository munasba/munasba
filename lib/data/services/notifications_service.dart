import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';

/// Wraps flutter_local_notifications + timezone to schedule reminders before
/// each event (1 day before, and 3 hours before — matching the plan doc's
/// suggestion). Call [init] once at app startup before scheduling anything.
class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      // NOTE: without a platform channel to read the device's real IANA
      // timezone name, this defaults to UTC. For correct local-time
      // reminders, add the `flutter_timezone` package and call
      // tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))
      // here instead of the UTC fallback below.
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {
      // ignore — falls back to whatever timezone package default applies
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Android 13+ requires explicit runtime permission for notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'dawakti_events',
      'تذكيرات المناسبات',
      channelDescription: 'تنبيهات قبل موعد كل مناسبة',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Schedules "1 day before" and "3 hours before" reminders for [event].
  /// Silently skips any reminder time that has already passed.
  static Future<void> scheduleEventReminders(EventItem event) async {
    if (event.date == null) return;
    await cancelEventReminders(event.id);

    DateTime eventDateTime = event.date!;
    if (event.time != null) {
      final parts = event.time!.split(':');
      if (parts.length == 2) {
        eventDateTime = DateTime(
          event.date!.year,
          event.date!.month,
          event.date!.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final reminders = {
      _stableNotificationId(event.id, 1): eventDateTime.subtract(const Duration(days: 1)),
      _stableNotificationId(event.id, 2): eventDateTime.subtract(const Duration(hours: 3)),
    };

    for (final entry in reminders.entries) {
      if (entry.value.isBefore(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        entry.key,
        'تذكير: ${event.name}',
        'مناسبتك قادمة قريبًا — لا تنسَ التحضيرات الأخيرة',
        tz.TZDateTime.from(entry.value, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelEventReminders(String eventId) async {
    await _plugin.cancel(_stableNotificationId(eventId, 1));
    await _plugin.cancel(_stableNotificationId(eventId, 2));
  }

  /// Deterministic small int id derived from the event's uuid + a slot
  /// number, since the plugin needs a stable int id (not a String uuid).
  static int _stableNotificationId(String eventId, int slot) {
    return (eventId.hashCode & 0x7fffffff) ~/ 10 * 10 + slot;
  }
}
