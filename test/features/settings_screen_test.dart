import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/features/settings/settings_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/state/reminder_providers.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  late MemoryMilkRepository repo;
  late FakeReminders reminders;

  Future<void> pumpSettings(
    WidgetTester tester, {
    bool allowNotifications = true,
  }) async {
    usePhoneScreen(tester);
    repo = MemoryMilkRepository.sample(today: DateTime(2026, 10, 2));
    reminders = FakeReminders(allowed: allowNotifications);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupProvider.overrideWithValue(FakeBackup()),
          updatesProvider.overrideWithValue(FakeUpdates()),
          milkRepositoryProvider.overrideWithValue(repo),
          remindersProvider.overrideWithValue(reminders),
          todayProvider.overrideWithValue(DateTime(2026, 10, 2)),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('editing the price saves it', (tester) async {
    await pumpSettings(tester);
    await tapOn(tester, find.text('Cow milk'));
    await tester.pumpAndSettle();

    await typeInto(tester, find.byType(TextField).at(1), '75');
    await tester.pump();
    expect(find.textContaining('Days already logged keep'), findsOneWidget);
    await tapOn(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('₹75 per litre'), findsOneWidget);
    final h = await repo.watchHousehold().first;
    expect(h.products.single.ratePaise, 7500);
  });

  testWidgets('a second milk type can be added', (tester) async {
    await pumpSettings(tester);
    await tapOn(tester, find.text('Add another milk type'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Buffalo milk'));
    await typeInto(tester, find.byType(TextField).at(1), '80');
    await tapOn(tester, find.text('½'));
    await tester.pump();
    await tapOn(tester, find.text('Save'));
    await tester.pumpAndSettle();

    final h = await repo.watchHousehold().first;
    expect(h.products.map((p) => p.name), ['Cow milk', 'Buffalo milk']);
  });

  testWidgets('changing the milkman number', (tester) async {
    await pumpSettings(tester);
    await tapOn(tester, find.text('Ramesh bhaiya'));
    await tester.pumpAndSettle();
    await typeInto(tester, find.byType(TextField).at(1), '91234 56789');
    await tester.pump();
    await tapOn(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('+91 91234 56789'), findsOneWidget);
  });

  testWidgets('renaming yourself saves without errors', (tester) async {
    await pumpSettings(tester);
    await tapOn(tester, find.text('Mom'));
    await tester.pumpAndSettle();
    await typeInto(tester, find.byType(TextField), 'Harsh');
    await tapOn(tester, find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Harsh'), findsOneWidget);
    final h = await repo.watchHousehold().first;
    expect(h.members['mom'], 'Harsh');
  });

  testWidgets('another phone can be removed after confirming', (tester) async {
    await pumpSettings(tester);
    await tapOn(tester, find.text('Dad'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Dad?'), findsOneWidget);
    await tapOn(tester, find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Dad'), findsNothing);
    final h = await repo.watchHousehold().first;
    expect(h.members.keys, ['mom']);
  });

  testWidgets('turning the reminder on schedules unlogged days', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('Off · tap to pick a time'), findsOneWidget);
    await tapOn(tester, find.byType(Switch));
    await tester.pumpAndSettle();

    expect(reminders.settings.enabled, isTrue);
    expect(find.textContaining('Every day at 10:00'), findsOneWidget);
  });

  testWidgets('blocked notifications explain how to allow them', (
    tester,
  ) async {
    await pumpSettings(tester, allowNotifications: false);
    await tapOn(tester, find.byType(Switch));
    await tester.pumpAndSettle();

    expect(reminders.settings.enabled, isFalse);
    expect(find.textContaining('Notifications are blocked'), findsOneWidget);
  });
}
