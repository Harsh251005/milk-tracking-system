import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/features/setup/setup_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  late FakeAccountRepository account;

  Future<void> pumpSetup(WidgetTester tester) async {
    usePhoneScreen(tester);
    account = FakeAccountRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(account),
          backupProvider.overrideWithValue(FakeBackup()),
        ],
        child: MaterialApp(theme: buildTheme(), home: const SetupScreen()),
      ),
    );
  }

  FilledButton primary(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('walks through name, milk and milkman', (tester) async {
    await pumpSetup(tester);

    expect(primary(tester).onPressed, isNull, reason: 'name required');
    expect(find.text('Mom'), findsNothing, reason: 'no name suggestions');
    await typeInto(tester, find.byType(TextField), 'Sunita');
    await tester.pump();
    await tapOn(tester, find.text('Next'));
    await tester.pumpAndSettle();

    // Milk step: price and quantity start empty.
    expect(primary(tester).onPressed, isNull);
    await tapOn(tester, find.text('Buffalo milk'));
    await typeInto(tester, find.byType(TextField).at(1), '80');
    await tapOn(tester, find.text('1½'));
    await tester.pump();
    await tapOn(tester, find.text('Next'));
    await tester.pumpAndSettle();

    await typeInto(tester, find.byType(TextField).at(0), 'Ramesh');
    await typeInto(tester, find.byType(TextField).at(1), '98765 43210');
    await tester.pump();
    await tapOn(tester, find.text('Finish'));
    await tester.pump();

    final c = account.created!;
    expect(c.name, 'Sunita');
    expect(c.product.name, 'Buffalo milk');
    expect(c.product.ratePaise, 8000);
    expect(c.product.usualMl, 1500);
    expect(c.milkmanName, 'Ramesh');
    expect(c.phone, '919876543210');
  });

  testWidgets('milkman step can be skipped; a bad number blocks Finish', (
    tester,
  ) async {
    await pumpSetup(tester);
    await typeInto(tester, find.byType(TextField), 'Dad');
    await tester.pump();
    await tapOn(tester, find.text('Next'));
    await tester.pumpAndSettle();
    await tapOn(tester, find.text('Cow milk'));
    await typeInto(tester, find.byType(TextField).at(1), '70');
    await tapOn(tester, find.text('1'));
    await tester.pump();
    await tapOn(tester, find.text('Next'));
    await tester.pumpAndSettle();

    await typeInto(tester, find.byType(TextField).at(1), '12345');
    await tester.pump();
    expect(find.text('Enter a 10-digit mobile number'), findsOneWidget);
    expect(primary(tester).onPressed, isNull);

    await tapOn(tester, find.text('Skip for now'));
    await tester.pump();
    expect(account.created!.milkmanName, isNull);
    expect(account.created!.phone, isNull);
  });
}
