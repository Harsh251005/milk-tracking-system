import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/features/settings/settings_screen.dart';
import 'package:milk_tracker/features/today/today_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/state/reminder_providers.dart';
import 'package:milk_tracker/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    FakeBackup backup,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milkRepositoryProvider.overrideWithValue(
            MemoryMilkRepository.sample(today: today),
          ),
          todayProvider.overrideWithValue(today),
          backupProvider.overrideWithValue(backup),
          remindersProvider.overrideWithValue(FakeReminders()),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Today nudges until backed up, then the card goes away', (
    tester,
  ) async {
    await pump(tester, TodayScreen(onOpenMonth: () {}), FakeBackup());
    expect(find.text('Keep your milk log safe'), findsOneWidget);

    await tapOn(tester, find.text('Back up'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your milk log safe'), findsNothing);
    expect(find.text('Backed up to mom@gmail.com.'), findsOneWidget);
  });

  testWidgets('"Not now" hides the nudge', (tester) async {
    await pump(tester, TodayScreen(onOpenMonth: () {}), FakeBackup());
    await tapOn(tester, find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your milk log safe'), findsNothing);
  });

  testWidgets('a failed backup says why, loudly', (tester) async {
    await pump(
      tester,
      TodayScreen(onOpenMonth: () {}),
      FakeBackup(fail: 'Backing up needs internet.'),
    );
    await tapOn(tester, find.text('Back up'));
    await tester.pumpAndSettle();
    expect(find.text('Backing up needs internet.'), findsOneWidget);
    expect(find.text('Keep your milk log safe'), findsOneWidget);
  });

  testWidgets('Settings shows the backup account once backed up', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsScreen(),
      FakeBackup(email: 'mom@gmail.com'),
    );
    await tester.scrollUntilVisible(find.text('Backed up'), 300);
    expect(find.text('Backed up'), findsOneWidget);
    expect(find.textContaining('mom@gmail.com'), findsOneWidget);
    expect(find.text('Keep your milk log safe'), findsNothing);
  });
}
