import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/features/settings/settings_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../helpers.dart';

void main() {
  late MemoryMilkRepository repo;

  Future<void> pumpSettings(WidgetTester tester) async {
    usePhoneScreen(tester);
    repo = MemoryMilkRepository.sample(today: DateTime(2026, 10, 2));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [milkRepositoryProvider.overrideWithValue(repo)],
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
}
