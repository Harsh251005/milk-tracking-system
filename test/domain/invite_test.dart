import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/invite.dart';

void main() {
  test('codes are six digits', () {
    for (var i = 0; i < 200; i++) {
      expect(newInviteCode(), matches(RegExp(r'^\d{6}$')));
    }
  });

  test('QR payload and typed codes parse to the same digits', () {
    expect(parseInviteCode(inviteQrPayload('482913')), '482913');
    expect(parseInviteCode('482 913'), '482913');
    expect(parseInviteCode('Code: 482-913'), '482913');
    expect(parseInviteCode('48291'), isNull);
    expect(parseInviteCode('https://example.com'), isNull);
  });

  test('formats for reading aloud', () {
    expect(formatInviteCode('482913'), '482 913');
  });

  test('expiry', () {
    final invite = Invite(
      code: '482913',
      householdId: 'h',
      invitedBy: 'Mom',
      expiresAt: DateTime(2026, 10, 3, 12),
    );
    expect(invite.isExpired(DateTime(2026, 10, 3, 11, 59)), isFalse);
    expect(invite.isExpired(DateTime(2026, 10, 3, 12)), isTrue);
  });
}
