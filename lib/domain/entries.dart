import 'dates.dart';
import 'models.dart';

/// "Got milk" for [date]. Each product is billed at [ratesPaise] when given,
/// else its saved rate. Zero quantities are dropped.
DayEntry gotEntry({
  required DateTime date,
  required Household household,
  required Map<String, int> quantitiesMl,
  required String byUid,
  required DateTime now,
  Map<String, int> ratesPaise = const {},
}) {
  final quantities = {
    for (final e in quantitiesMl.entries)
      if (e.value > 0) e.key: e.value,
  };
  return DayEntry(
    date: dateOnly(date),
    status: DayStatus.got,
    quantitiesMl: quantities,
    ratesPaise: {
      for (final p in household.products)
        if (quantities.containsKey(p.id)) p.id: ratesPaise[p.id] ?? p.ratePaise,
    },
    byUid: byUid,
    byName: household.members[byUid],
    at: now,
  );
}

DayEntry skippedEntry({
  required DateTime date,
  required Household household,
  required String byUid,
  required DateTime now,
}) => DayEntry(
  date: dateOnly(date),
  status: DayStatus.skipped,
  quantitiesMl: const {},
  ratesPaise: const {},
  byUid: byUid,
  byName: household.members[byUid],
  at: now,
);

/// What the editor starts with: the existing entry, else each product's usual amount.
Map<String, int> initialQuantities(Household household, DayEntry? existing) {
  if (existing != null && existing.status == DayStatus.got) {
    return {
      for (final p in household.products)
        p.id: existing.quantitiesMl[p.id] ?? 0,
    };
  }
  return {for (final p in household.products) p.id: p.usualMl};
}

/// Prices the editor starts with: the existing entry's, else the saved ones.
Map<String, int> initialRates(Household household, DayEntry? existing) => {
  for (final p in household.products)
    p.id: existing?.ratesPaise[p.id] ?? p.ratePaise,
};
