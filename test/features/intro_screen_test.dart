import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/features/intro/intro_screen.dart';
import 'package:milk_tracker/state/intro_provider.dart';
import 'package:milk_tracker/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  Future<int> pumpIntro(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    usePhoneScreen(tester);
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(411, 914),
            disableAnimations: reduceMotion,
          ),
          child: IntroScreen(onDone: () => done++),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    return done;
  }

  // The illustrations loop forever, so pump fixed time, never "settle".
  Future<void> step(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pump(); // starts the page slide
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Next walks through three pages, then Get started finishes', (
    tester,
  ) async {
    var done = 0;
    usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: IntroScreen(onDone: () => done++),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Milk, logged in one tap'), findsOneWidget);
    await step(tester, 'Next');
    expect(find.text('The whole family, in sync'), findsOneWidget);
    await step(tester, 'Next');
    expect(find.text('The bill, ready on WhatsApp'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    await step(tester, 'Get started');
    expect(done, 1);
  });

  testWidgets('Skip finishes straight away', (tester) async {
    var done = 0;
    usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: IntroScreen(onDone: () => done++),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await step(tester, 'Skip');
    expect(done, 1);
  });

  testWidgets('with reduced motion the pictures hold still', (tester) async {
    await pumpIntro(tester, reduceMotion: true);
    // Nothing keeps animating, so the screen settles.
    await tester.pumpAndSettle();
    expect(find.text('Milk, logged in one tap'), findsOneWidget);
  });

  test('the intro is remembered once seen', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(introSeenProvider.future), isFalse);
    await c.read(introSeenProvider.notifier).markSeen();

    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    expect(await fresh.read(introSeenProvider.future), isTrue);
  });
}
