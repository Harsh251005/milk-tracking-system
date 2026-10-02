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
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
      enabled: p.getBool(_enabled) ?? false,
      hour: p.getInt(_hour) ?? 10,
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
    return await android?.requestNotificationsPermission() ?? false;
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
