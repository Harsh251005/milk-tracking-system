import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/features/today/today_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  Future<void> pumpToday(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milkRepositoryProvider.overrideWithValue(
            MemoryMilkRepository.sample(today: today),
          ),
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
}
