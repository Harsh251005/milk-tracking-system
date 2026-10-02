import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';

/// Phone-side reminder scheduling. Interface so tests can swap it out.
abstract interface class Reminders {
  Future<ReminderSettings> load();
  Future<void> save(ReminderSettings settings);

  /// Asks Android for permission to show notifications. True if allowed.
  Future<bool> requestPermission();

  /// Asks only the first time it is called on this phone; afterwards
  /// returns null without asking again.
  Future<bool?> requestPermissionOnce();

  /// Replaces all scheduled reminders with [times].
  Future<void> schedule(List<DateTime> times);
}

class LocalNotificationReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _channel = AndroidNotificationDetails(
    'daily_reminder',
    'Daily reminder',
    channelDescription: 'Reminds you to log the milk each day',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_milk'),
      ),
    );
  }();

  static const _enabled = 'reminder.enabled';
  static const _hour = 'reminder.hour';
  static const _minute = 'reminder.minute';

  @override
  Future<ReminderSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return ReminderSettings(
      // On by default; the person can turn it off or change the time.
      enabled: p.getBool(_enabled) ?? true,
      hour: p.getInt(_hour) ?? 21,
      minute: p.getInt(_minute) ?? 0,
    );
  }

  @override
  Future<void> save(ReminderSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabled, s.enabled);
    await p.setInt(_hour, s.hour);
    await p.setInt(_minute, s.minute);
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    // Already allowed (always the case before Android 13): don't prompt.
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  static const _asked = 'reminder.permissionAsked';

  @override
  Future<bool?> requestPermissionOnce() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_asked) ?? false) return null;
    await p.setBool(_asked, true);
    return requestPermission();
  }

  @override
  Future<void> schedule(List<DateTime> times) async {
    await _init();
    await _plugin.cancelAll();
    for (final at in times) {
      await _plugin.zonedSchedule(
        id: reminderId(at),
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(android: _channel),
        // Inexact: may arrive a few minutes late, but needs no special
        // "exact alarm" permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Did milk come today?',
        body: 'Tap to log it in Milk Tracker.',
      );
    }
  }
}
