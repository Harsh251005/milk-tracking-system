import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/features/whats_new/whats_new_sheet.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../helpers.dart';

void main() {
  testWidgets("What's new lists the changes and closes with Got it", (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showWhatsNew(context, [
                (
                  '1.0.4',
                  ['Share sends the app itself.', 'Clear update steps.'],
                ),
              ]),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Share sends the app itself.'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsNothing);
  });
}
