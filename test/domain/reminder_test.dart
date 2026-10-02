import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/reminder.dart';

void main() {
  const on = ReminderSettings(enabled: true, hour: 10, minute: 0);

  test('off means no reminders', () {
    expect(
      reminderTimes(
        settings: const ReminderSettings(enabled: false),
        now: DateTime(2026, 10, 2, 8),
        loggedDayKeys: {},
      ),
      isEmpty,
    );
  });

  test('today still counts before the time, logged days are skipped', () {
    final times = reminderTimes(
      settings: on,
      now: DateTime(2026, 10, 2, 8),
      loggedDayKeys: {'2026-10-03'},
    );
    expect(times.first, DateTime(2026, 10, 2, 10));
    expect(times, isNot(contains(DateTime(2026, 10, 3, 10))));
    expect(times.length, reminderHorizonDays - 1);
  });

  test('after the time, today is skipped', () {
    final times = reminderTimes(
      settings: on,
      now: DateTime(2026, 10, 2, 10, 1),
      loggedDayKeys: {},
    );
    expect(times.first, DateTime(2026, 10, 3, 10));
  });

  test('ids are unique per day and fit in an int', () {
    expect(reminderId(DateTime(2026, 10, 2)), 20261002);
    expect(reminderId(DateTime(2026, 12, 31)), lessThan(1 << 31));
  });

  test('the reminder is on by default, at 9 PM', () {
    const s = ReminderSettings();
    expect(s.enabled, isTrue);
    expect((s.hour, s.minute), (21, 0));
  });
}
