import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/phone.dart';

void main() {
  test('accepts the ways people type Indian mobile numbers', () {
    for (final input in [
      '9876543210',
      '98765 43210',
      '+91 98765-43210',
      '91 9876543210',
      '09876543210',
    ]) {
      expect(normalizeIndianMobile(input), '919876543210', reason: input);
    }
  });

  test('rejects landlines, short numbers and junk', () {
    for (final input in ['12345', '5876543210', '98765432100', 'abc', '']) {
      expect(normalizeIndianMobile(input), isNull, reason: input);
    }
  });

  test('formats for display', () {
    expect(formatIndianMobile('919876543210'), '+91 98765 43210');
  });
}
