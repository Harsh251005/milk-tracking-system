import 'dart:math';

/// A short-lived code that lets another phone join a household.
class Invite {
  const Invite({
    required this.code,
    required this.householdId,
    required this.invitedBy,
    required this.expiresAt,
  });

  /// Six digits, e.g. "482913".
  final String code;
  final String householdId;

  /// Display name of the member who created it ("Mom").
  final String invitedBy;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
}

const inviteLifetime = Duration(hours: 24);

final _random = Random.secure();

String newInviteCode() => List.generate(6, (_) => _random.nextInt(10)).join();

/// "482913" -> "482 913", easier to read aloud.
String formatInviteCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

const _qrPrefix = 'milktracker:join:';

String inviteQrPayload(String code) => '$_qrPrefix$code';

/// Accepts what the scanner reads, or what someone types/pastes
/// ("482 913", "Code: 482913"). Returns the 6 digits, or null.
String? parseInviteCode(String raw) {
  final text = raw.startsWith(_qrPrefix)
      ? raw.substring(_qrPrefix.length)
      : raw;
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.length == 6 ? digits : null;
}
