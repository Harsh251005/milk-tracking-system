import 'models.dart';

/// A product whose price for this log differs from its saved price.
class RateChange {
  const RateChange(this.product, this.newRatePaise);

  final Product product;
  final int newRatePaise;
}

/// Only products actually received (quantity > 0) count.
List<RateChange> rateChanges(
  Household household,
  Map<String, int> quantitiesMl,
  Map<String, int> ratesPaise,
) => [
  for (final p in household.products)
    if ((quantitiesMl[p.id] ?? 0) > 0 &&
        ratesPaise[p.id] != null &&
        ratesPaise[p.id] != p.ratePaise)
      RateChange(p, ratesPaise[p.id]!),
];

Map<String, int> savedRates(Household household) => {
  for (final p in household.products) p.id: p.ratePaise,
};
