import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/invite.dart';
import 'package:milk_tracker/features/join/join_screen.dart';
import 'package:milk_tracker/state/providers.dart';
import 'package:milk_tracker/ui/theme.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  final live = Invite(
    code: '482913',
    householdId: 'h1',
    invitedBy: 'Mom',
    expiresAt: DateTime.now().add(const Duration(hours: 5)),
  );
  final expired = Invite(
    code: '111111',
    householdId: 'h1',
    invitedBy: 'Mom',
    expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
  );
  late FakeAccountRepository account;

  Future<void> pumpJoin(WidgetTester tester) async {
    usePhoneScreen(tester);
    account = FakeAccountRepository(
      invites: {live.code: live, expired.code: expired},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountRepositoryProvider.overrideWithValue(account)],
        child: MaterialApp(
          theme: buildTheme(),
          // Opened on top of setup, as in the app.
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const JoinScreen()),
                  ),
                  child: const Text('open join'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open join'));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await typeInto(tester, find.byType(TextField), code);
    await tester.pump();
    await tapOn(tester, find.text('Find my family'));
    await tester.pumpAndSettle();
  }

  testWidgets('a typed code finds the family, then joins with a name', (
    tester,
  ) async {
    await pumpJoin(tester);
    await enterCode(tester, '482 913');

    expect(find.text("Join Mom's tracker"), findsOneWidget);
    expect(find.text('Dad'), findsNothing, reason: 'no name suggestions');
    await typeInto(tester, find.byType(TextField), 'Ramesh');
    await tester.pump();
    await tapOn(tester, find.text('Join'));
    await tester.pumpAndSettle();

    expect(account.joined?.name, 'Ramesh');
    expect(account.joined?.invite.householdId, 'h1');
    expect(find.byType(JoinScreen), findsNothing, reason: 'closes after join');
  });

  testWidgets('an unknown code explains what to do', (tester) async {
    await pumpJoin(tester);
    await enterCode(tester, '999999');
    expect(find.textContaining("doesn't match"), findsOneWidget);
    expect(account.joined, isNull);
  });

  testWidgets('an expired code says who to ask', (tester) async {
    await pumpJoin(tester);
    await enterCode(tester, '111111');
    expect(find.textContaining('Ask Mom to make a new one'), findsOneWidget);
  });

  testWidgets('Find stays disabled until six digits are typed', (tester) async {
    await pumpJoin(tester);
    await typeInto(tester, find.byType(TextField), '4829');
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Find my family'),
    );
    expect(button.onPressed, isNull);
  });
}
