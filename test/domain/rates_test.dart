import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/entries.dart';
import 'package:milk_tracker/domain/models.dart';
import 'package:milk_tracker/domain/rates.dart';

const household = Household(
  id: 'h',
  name: 'Home',
  products: [
    Product(id: 'cow', name: 'Cow milk', ratePaise: 7000, usualMl: 1000),
    Product(id: 'buffalo', name: 'Buffalo milk', ratePaise: 8000, usualMl: 0),
  ],
  members: {'mom': 'Mom'},
);

void main() {
  test('only received products with a different price count as changes', () {
    final changes = rateChanges(
      household,
      {'cow': 1000, 'buffalo': 0},
      {'cow': 7200, 'buffalo': 9000},
    );
    expect(changes.map((c) => (c.product.id, c.newRatePaise)), [('cow', 7200)]);
  });

  test('same prices mean no changes', () {
    expect(
      rateChanges(household, {'cow': 1000}, savedRates(household)),
      isEmpty,
    );
  });

  test('got entry uses the given price, else the saved one', () {
    final e = gotEntry(
      date: DateTime(2026, 10, 2),
      household: household,
      quantitiesMl: {'cow': 1000, 'buffalo': 500},
      ratesPaise: {'cow': 7200},
      byUid: 'mom',
      now: DateTime(2026, 10, 2),
    );
    expect(e.ratesPaise, {'cow': 7200, 'buffalo': 8000});
  });

  test('editing an old day starts from the price it was logged at', () {
    final old = gotEntry(
      date: DateTime(2026, 9, 2),
      household: household,
      quantitiesMl: {'cow': 1000},
      ratesPaise: {'cow': 6800},
      byUid: 'mom',
      now: DateTime(2026, 9, 2),
    );
    expect(initialRates(household, old), {'cow': 6800, 'buffalo': 8000});
  });
}
