/// Indian mobile numbers, stored as `91XXXXXXXXXX` (the form wa.me wants).
library;

/// Accepts "98765 43210", "+91 98765-43210", "098765 43210", "919876543210".
/// Returns `919876543210`, or null if it isn't a valid Indian mobile number.
String? normalizeIndianMobile(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return null;
  return '91$digits';
}

/// `919876543210` -> `+91 98765 43210`.
String formatIndianMobile(String stored) {
  if (stored.length != 12) return '+$stored';
  return '+91 ${stored.substring(2, 7)} ${stored.substring(7)}';
}
