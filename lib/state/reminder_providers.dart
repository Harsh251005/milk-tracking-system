import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminders.dart';
import '../domain/dates.dart';
import '../domain/reminder.dart';
import 'providers.dart';

final remindersProvider = Provider<Reminders>(
  (ref) => LocalNotificationReminders(),
);

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() => ref.read(remindersProvider).load();

  Future<void> set(ReminderSettings s) async {
    await ref.read(remindersProvider).save(s);
    state = AsyncData(s);
  }
}

final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

/// Keeps scheduled reminders in step with the settings and the log: runs
/// again whenever either changes, on this phone or synced from another.
final reminderSyncProvider = FutureProvider<void>((ref) async {
  final settings = await ref.watch(reminderSettingsProvider.future);
  final today = ref.watch(todayProvider);
  final thisMonth = monthOf(today);
  final entries = [
    ...await ref.watch(monthEntriesProvider(thisMonth).future),
    ...await ref.watch(monthEntriesProvider(addMonths(thisMonth, 1)).future),
  ];
  await ref
      .read(remindersProvider)
      .schedule(
        reminderTimes(
          settings: settings,
          now: DateTime.now(),
          loggedDayKeys: {for (final e in entries) dayKey(e.date)},
        ),
      );
});
