import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/data/share_prefs.dart';
import 'package:milk_tracker/features/share/share_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  final today = DateTime(2026, 10, 10);

  Future<void> pumpShare(WidgetTester tester, MessageKind kind) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupProvider.overrideWithValue(FakeBackup()),
          milkRepositoryProvider.overrideWithValue(
            MemoryMilkRepository.sample(today: today),
          ),
          todayProvider.overrideWithValue(today),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: ShareScreen(kind: kind),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String message(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bill message follows the switches, and they are remembered', (
    tester,
  ) async {
    await pumpShare(tester, MessageKind.bill);
    expect(message(tester), startsWith('October 2026'));
    expect(message(tester), contains('Amount: ₹'));

    await tapOn(tester, find.text('Total amount'));
    await tester.pumpAndSettle();
    expect(message(tester), isNot(contains('₹')));

    expect((await SharePrefs().loadBill()).amount, isFalse);
  });

  testWidgets('tomorrow: usual amount, or no milk', (tester) async {
    await pumpShare(tester, MessageKind.tomorrow);
    expect(message(tester), 'Tomorrow (Sun, 11 Oct): 1 L');

    await tapOn(tester, find.text('No milk tomorrow'));
    await tester.pumpAndSettle();
    expect(message(tester), 'Tomorrow (Sun, 11 Oct): no milk');
  });

  testWidgets('today asks to log first when nothing is logged', (tester) async {
    await pumpShare(tester, MessageKind.today);
    expect(find.textContaining("Today isn't logged yet"), findsOneWidget);
    final send = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(send.onPressed, isNull);
  });
}
