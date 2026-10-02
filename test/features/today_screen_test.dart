import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/memory_milk_repository.dart';
import 'package:milk_tracker/domain/models.dart';
import 'package:milk_tracker/domain/release.dart';
import 'package:milk_tracker/features/today/today_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  final today = DateTime(2026, 10, 2);

  late MemoryMilkRepository repo;

  Future<void> pumpToday(WidgetTester tester) async {
    usePhoneScreen(tester);
    repo = MemoryMilkRepository.sample(today: today);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupProvider.overrideWithValue(FakeBackup()),
          updatesProvider.overrideWithValue(FakeUpdates()),
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

  testWidgets('a new day while the app stays open starts a fresh log', (
    tester,
  ) async {
    usePhoneScreen(tester);
    repo = MemoryMilkRepository.sample(today: today);
    final container = ProviderContainer(
      overrides: [
        backupProvider.overrideWithValue(FakeBackup()),
        updatesProvider.overrideWithValue(FakeUpdates()),
        milkRepositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWith((ref) => ref.watch(_testDay)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: TodayScreen(onOpenMonth: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got 1 L'));
    await tester.pumpAndSettle();
    expect(find.text('1 L received'), findsOneWidget);

    container.read(_testDay.notifier).set(DateTime(2026, 10, 3));
    await tester.pumpAndSettle();

    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Got 1 L'), findsOneWidget);
    expect(find.text('1 L received'), findsNothing);
  });

  testWidgets('going away marks the chosen days as no milk', (tester) async {
    await pumpToday(tester);
    await tapOn(tester, find.text('Going away?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No milk on Sat, 3 Oct'), findsOneWidget);

    await tapOn(tester, find.text('Only mark the days'));
    await tester.pumpAndSettle();

    final entries = await repo.watchMonth((year: 2026, month: 10)).first;
    final tomorrow = entries.where((e) => e.date == DateTime(2026, 10, 3));
    expect(tomorrow.single.status, DayStatus.skipped);
    expect(tomorrow.single.byName, 'Mom');
  });

  testWidgets('a newer published version shows the update banner', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milkRepositoryProvider.overrideWithValue(
            MemoryMilkRepository.sample(today: today),
          ),
          todayProvider.overrideWithValue(today),
          backupProvider.overrideWithValue(FakeBackup()),
          updatesProvider.overrideWithValue(
            FakeUpdates(
              installed: '1.0.0',
              published: const AppRelease(version: '1.0.1', apkUrl: 'u'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: TodayScreen(onOpenMonth: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update available · version 1.0.1'), findsOneWidget);
    expect(find.textContaining('Package installer'), findsOneWidget);
    expect(find.textContaining('Allow from this source'), findsOneWidget);
  });

  testWidgets('Update downloads in the app; a failure says why', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final updates = FakeUpdates(
      installed: '1.0.0',
      published: const AppRelease(version: '1.0.1', apkUrl: 'u'),
    )..failWith = 'The download stopped. Check the internet and try again.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milkRepositoryProvider.overrideWithValue(
            MemoryMilkRepository.sample(today: today),
          ),
          todayProvider.overrideWithValue(today),
          backupProvider.overrideWithValue(FakeBackup()),
          updatesProvider.overrideWithValue(updates),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: Scaffold(body: TodayScreen(onOpenMonth: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The download stopped'), findsOneWidget);

    updates.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(updates.installs, 1);
    // Back from Android's screen without finishing: guide them.
    expect(find.textContaining("Didn't finish?"), findsOneWidget);
    await tester.tap(find.text('Update again'));
    await tester.pumpAndSettle();
    expect(updates.installs, 2);
  });

  testWidgets('no banner when up to date', (tester) async {
    await pumpToday(tester);
    expect(find.textContaining('Update available'), findsNothing);
  });
}

class _TestDay extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(2026, 10, 2);

  void set(DateTime day) => state = day;
}

final _testDay = NotifierProvider<_TestDay, DateTime>(_TestDay.new);
