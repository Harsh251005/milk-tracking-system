import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/features/today/today_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  late MemoryMilkRepository repo;

  Future<void> pumpToday(WidgetTester tester) async {
    repo = MemoryMilkRepository.sample(today: today);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milkRepositoryProvider.overrideWithValue(repo),
          todayProvider.overrideWithValue(today),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: TodayScreen(onOpenMonth: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('usual quantity is prefilled and one tap logs it', (
    tester,
  ) async {
    await pumpToday(tester);
    expect(find.text('Got 1 L'), findsOneWidget);

    await tester.tap(find.text('Got 1 L'));
    await tester.pumpAndSettle();

    expect(find.text('1 L received'), findsOneWidget);
    expect(find.textContaining('Logged by you'), findsOneWidget);
  });

  testWidgets('quick pick changes the amount before logging', (tester) async {
    await pumpToday(tester);
    await tester.tap(find.text('1½'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got 1½ L'));
    await tester.pumpAndSettle();
    expect(find.text('1½ L received'), findsOneWidget);
  });

  testWidgets('no milk today is recorded', (tester) async {
    await pumpToday(tester);
    await tester.tap(find.text('No milk today'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Marked by you'), findsOneWidget);
  });

  Future<void> enterPrice(WidgetTester tester, String price) async {
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), price);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a different price asks; "only for this day" keeps the saved price',
    (tester) async {
      await pumpToday(tester);
      await enterPrice(tester, '72');
      expect(find.textContaining('(usually ₹70)'), findsOneWidget);

      await tester.tap(find.text('Got 1 L'));
      await tester.pumpAndSettle();
      expect(find.text('The price is different'), findsOneWidget);

      await tester.tap(find.text('₹72 only for this day'));
      await tester.pumpAndSettle();
      expect(find.text('₹72 per litre today (usually ₹70)'), findsOneWidget);
      final h = await repo.watchHousehold().first;
      expect(h.products.single.ratePaise, 7000);
    },
  );

  testWidgets('"from now on" updates the saved price', (tester) async {
    await pumpToday(tester);
    await enterPrice(tester, '72');
    await tester.tap(find.text('Got 1 L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use ₹72 from now on'));
    await tester.pumpAndSettle();

    final h = await repo.watchHousehold().first;
    expect(h.products.single.ratePaise, 7200);
    expect(find.text('1 L received'), findsOneWidget);
    expect(find.textContaining('usually'), findsNothing);
  });

  testWidgets('"keep" logs at the saved price', (tester) async {
    await pumpToday(tester);
    await enterPrice(tester, '72');
    await tester.tap(find.text('Got 1 L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep ₹70'));
    await tester.pumpAndSettle();

    final entries = await repo.watchMonth((year: 2026, month: 10)).first;
    expect(entries.last.ratesPaise, {'cow': 7000});
  });

  testWidgets('backing out of the question saves nothing', (tester) async {
    await pumpToday(tester);
    await enterPrice(tester, '72');
    await tester.tap(find.text('Got 1 L'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // tap outside the dialog
    await tester.pumpAndSettle();

    expect(find.text('Got 1 L'), findsOneWidget);
    final entries = await repo.watchMonth((year: 2026, month: 10)).first;
    expect(entries.where((e) => e.date == today), isEmpty);
  });
}
