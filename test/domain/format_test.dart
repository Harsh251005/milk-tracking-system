import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/format.dart';

void main() {
  test('quantities use fraction glyphs for quarter litres', () {
    expect(formatQty(250), '¼');
    expect(formatQty(500), '½');
    expect(formatQty(1000), '1');
    expect(formatQty(1500), '1½');
    expect(formatQty(2750), '2¾');
    expect(formatQty(0), '0');
    expect(formatLitres(1500), '1½ L');
  });

  test('odd quantities fall back to decimals without trailing zeros', () {
    expect(formatQty(1200), '1.2');
    expect(formatQty(1001), '1.001');
  });

  test('rupees use Indian grouping and hide zero paise', () {
    expect(formatRupees(196000), '₹1,960');
    expect(formatRupees(12345600), '₹1,23,456');
    expect(formatRupees(6850), '₹68.50');
  });

  test('typed prices parse to paise', () {
    expect(parseRupees('72'), 7200);
    expect(parseRupees('72.5'), 7250);
    expect(parseRupees(' ₹ 72.50 '), 7250);
    expect(parseRupees('1,200'), 120000);
    expect(parseRupees('0'), isNull);
    expect(parseRupees('72.555'), isNull);
    expect(parseRupees('abc'), isNull);
    expect(parseRupees(''), isNull);
  });
}
