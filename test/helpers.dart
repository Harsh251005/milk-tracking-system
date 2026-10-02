import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders tests on a phone-shaped screen (the test default is 800×600
/// landscape, which pushes buttons off-screen).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Scrolls [finder] into view first, like a person would, then taps it.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Scrolls the field into view, then types into it.
Future<void> typeInto(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
}
