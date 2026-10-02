import 'package:intl/intl.dart';

const _fractions = {250: '¼', 500: '½', 750: '¾'};

/// 1500 -> "1½", 250 -> "¼", 2000 -> "2", 1200 -> "1.2".
String formatQty(int ml) {
  final whole = ml ~/ 1000;
  final rest = ml % 1000;
  if (rest == 0) return '$whole';
  final glyph = _fractions[rest];
  if (glyph != null) return whole == 0 ? glyph : '$whole$glyph';
  return (ml / 1000).toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// 1500 -> "1½ L".
String formatLitres(int ml) => '${formatQty(ml)} L';

final _rupeesWhole = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _rupeesPaise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// 196000 -> "₹1,960", 6850 -> "₹68.50".
String formatRupees(int paise) => paise % 100 == 0
    ? _rupeesWhole.format(paise ~/ 100)
    : _rupeesPaise.format(paise / 100);

/// Parses what someone types as a price: "72", "72.5", "₹ 72.50".
/// Returns paise, or null if it isn't a positive amount with at most 2 decimals.
int? parseRupees(String input) {
  final s = input.replaceAll(RegExp(r'[₹,\s]'), '');
  final m = RegExp(r'^(\d{1,6})(?:\.(\d{0,2}))?$').firstMatch(s);
  if (m == null) return null;
  final paise =
      int.parse(m[1]!) * 100 + int.parse((m[2] ?? '').padRight(2, '0'));
  return paise > 0 ? paise : null;
}
