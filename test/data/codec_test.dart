import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/data/firebase/codec.dart';
import 'package:milk_tracker/domain/models.dart';

void main() {
  test('household reads members, milkman and products in creation order', () {
    final h = householdFromDoc('h1', {
      'name': 'Home',
      'members': {'u1': 'Mom', 'u2': 'Dad'},
      'products': {
        'p200': {'name': 'Curd', 'ratePaise': 12000, 'usualMl': 0},
        'p100': {'name': 'Cow milk', 'ratePaise': 7000, 'usualMl': 1000},
      },
      'milkman': {'name': 'Ramesh', 'phone': '919876543210'},
    });
    expect(h.members, {'u1': 'Mom', 'u2': 'Dad'});
    expect(h.products.map((p) => p.name), ['Cow milk', 'Curd']);
    expect(h.milkmanPhone, '919876543210');
  });

  test('household without a milkman', () {
    final h = householdFromDoc('h1', {
      'members': {'u1': 'Mom'},
      'products': <String, dynamic>{},
      'milkman': <String, dynamic>{},
    });
    expect(h.milkmanName, isNull);
    expect(h.milkmanPhone, isNull);
  });

  test('entries round-trip, keyed by local date', () {
    final e = DayEntry(
      date: DateTime(2026, 10, 2),
      status: DayStatus.got,
      quantitiesMl: {'p1': 1500},
      ratesPaise: {'p1': 7200},
      byUid: 'u1',
      at: DateTime(2026, 10, 2, 7, 40),
    );
    final map = entryToMap(e);
    expect(map['date'], '2026-10-02');
    expect(map['at'], isA<Timestamp>());

    final back = entryFromMap(map);
    expect(back.date, DateTime(2026, 10, 2));
    expect(back.status, DayStatus.got);
    expect(back.quantitiesMl, {'p1': 1500});
    expect(back.ratesPaise, {'p1': 7200});
    expect(back.at, DateTime(2026, 10, 2, 7, 40));
  });

  test('numbers stored as doubles still read back as ints', () {
    final back = entryFromMap({
      'date': '2026-10-02',
      'status': 'got',
      'quantitiesMl': {'p1': 1500.0},
      'ratesPaise': {'p1': 7000.0},
      'byUid': 'u1',
      'at': Timestamp.fromDate(DateTime(2026, 10, 2)),
    });
    expect(back.quantitiesMl, {'p1': 1500});
  });

  test('empty milkman fields are left out', () {
    expect(milkmanToMap('', null), isEmpty);
    expect(milkmanToMap('Ramesh', '919876543210'), {
      'name': 'Ramesh',
      'phone': '919876543210',
    });
  });

  test('new product ids sort in creation order', () {
    final a = newProductId(DateTime(2026, 10, 2));
    final b = newProductId(DateTime(2026, 10, 3));
    expect(a.compareTo(b), lessThan(0));
  });
}
