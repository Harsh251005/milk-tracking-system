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
}
