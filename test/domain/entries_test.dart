import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/entries.dart';
import 'package:milk_tracker/domain/models.dart';

const household = Household(
  id: 'h',
  name: 'Home',
  products: [
    Product(id: 'cow', name: 'Cow milk', ratePaise: 7000, usualMl: 1000),
    Product(id: 'curd', name: 'Curd', ratePaise: 12000, usualMl: 0),
  ],
  members: {'mom': 'Mom'},
);

void main() {
  test('got entry snapshots rates and drops zero quantities', () {
    final e = gotEntry(
      date: DateTime(2026, 10, 2, 9, 30),
      household: household,
      quantitiesMl: {'cow': 1500, 'curd': 0},
      byUid: 'mom',
      now: DateTime(2026, 10, 2, 9, 30),
    );
    expect(e.date, DateTime(2026, 10, 2));
    expect(e.quantitiesMl, {'cow': 1500});
    expect(e.ratesPaise, {'cow': 7000});
  });

  test('editor starts from usual quantities, or the existing entry', () {
    expect(initialQuantities(household, null), {'cow': 1000, 'curd': 0});
    final existing = gotEntry(
      date: DateTime(2026, 10, 2),
      household: household,
      quantitiesMl: {'cow': 2000},
      byUid: 'mom',
      now: DateTime(2026, 10, 2),
    );
    expect(initialQuantities(household, existing), {'cow': 2000, 'curd': 0});
  });
}
