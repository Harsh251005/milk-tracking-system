import 'dates.dart';
import 'models.dart';

class MonthSummary {
  const MonthSummary({
    required this.totalMl,
    required this.mlByProduct,
    required this.amountPaise,
    required this.gotDays,
    required this.skippedDays,
    required this.missingDays,
  });

  final int totalMl;
  final Map<String, int> mlByProduct;
  final int amountPaise;
  final int gotDays;
  final int skippedDays;

  /// Past days of the month (before [today], from [trackingSince]) with no
  /// entry at all.
  final List<DateTime> missingDays;
}

/// Totals for one month. Each entry is billed at the rate stored on it.
MonthSummary summarizeMonth({
  required YearMonth month,
  required Iterable<DayEntry> entries,
  required DateTime today,
  DateTime? trackingSince,
}) {
  final mlByProduct = <String, int>{};
  var paiseTimesMl = 0;
  var got = 0;
  var skipped = 0;
  final logged = <String>{};

  for (final e in entries) {
    if (e.date.year != month.year || e.date.month != month.month) continue;
    logged.add(dayKey(e.date));
    if (e.status == DayStatus.skipped) {
      skipped++;
      continue;
    }
    got++;
    e.quantitiesMl.forEach((productId, ml) {
      mlByProduct[productId] = (mlByProduct[productId] ?? 0) + ml;
      paiseTimesMl += ml * (e.ratesPaise[productId] ?? 0);
    });
  }

  final todayOnly = dateOnly(today);
  final missing = <DateTime>[
    for (var day = 1; day <= daysInMonth(month.year, month.month); day++)
      if (isExpectedDay(
            DateTime(month.year, month.month, day),
            today: todayOnly,
            trackingSince: trackingSince,
          ) &&
          !logged.contains(dayKey(DateTime(month.year, month.month, day))))
        DateTime(month.year, month.month, day),
  ];

  return MonthSummary(
    totalMl: mlByProduct.values.fold(0, (a, b) => a + b),
    mlByProduct: mlByProduct,
    // Rate is per 1000 ml; round to the nearest paisa once, at the end.
    amountPaise: (paiseTimesMl + 500) ~/ 1000,
    gotDays: got,
    skippedDays: skipped,
    missingDays: missing,
  );
}

/// A past day on or after tracking started, so an empty one is "not logged".
bool isExpectedDay(
  DateTime day, {
  required DateTime today,
  DateTime? trackingSince,
}) =>
    day.isBefore(dateOnly(today)) &&
    (trackingSince == null || !day.isBefore(dateOnly(trackingSince)));
