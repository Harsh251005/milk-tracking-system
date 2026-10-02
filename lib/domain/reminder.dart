import 'dates.dart';

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 10,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

/// How far ahead reminders are scheduled. Re-planned every time the app
/// opens, so this only matters if nobody opens it for two weeks.
const reminderHorizonDays = 14;

/// When to remind: at the set time on each of the coming days that isn't
/// logged yet and hasn't already passed.
List<DateTime> reminderTimes({
  required ReminderSettings settings,
  required DateTime now,
  required Set<String> loggedDayKeys,
}) {
  if (!settings.enabled) return const [];
  final today = dateOnly(now);
  return [
    for (var i = 0; i < reminderHorizonDays; i++)
      if (DateTime(
            today.year,
            today.month,
            today.day + i,
            settings.hour,
            settings.minute,
          )
          case final at
          when at.isAfter(now) && !loggedDayKeys.contains(dayKey(at)))
        at,
  ];
}

/// Stable notification id per day: 2026-10-02 -> 20261002.
int reminderId(DateTime day) => day.year * 10000 + day.month * 100 + day.day;
