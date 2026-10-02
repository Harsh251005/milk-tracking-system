import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/models.dart';
import 'package:milk_tracker/domain/share_text.dart';

const cow = Product(
  id: 'cow',
  name: 'Cow milk',
  ratePaise: 7000,
  usualMl: 1000,
);
const curd = Product(id: 'curd', name: 'Curd', ratePaise: 12000, usualMl: 0);
const home = Household(
  id: 'h',
  name: 'Home',
  products: [cow],
  members: {'mom': 'Mom'},
  milkmanName: 'Ramesh',
);

DayEntry got(int day, int ml, {int rate = 7000, String id = 'cow'}) => DayEntry(
  date: DateTime(2026, 10, day),
  status: DayStatus.got,
  quantitiesMl: {id: ml},
  ratesPaise: {id: rate},
  byUid: 'mom',
  at: DateTime(2026, 10, day, 7),
);

DayEntry skipped(int day) => DayEntry(
  date: DateTime(2026, 10, day),
  status: DayStatus.skipped,
  quantitiesMl: const {},
  ratesPaise: const {},
  byUid: 'mom',
  at: DateTime(2026, 10, day, 7),
);

void main() {
  const oct = (year: 2026, month: 10);
  final entries = [got(1, 1000), got(2, 1500), skipped(3), got(4, 1000)];

  String bill(BillOptions o, {List<DayEntry>? e, Household h = home}) =>
      billMessage(
        household: h,
        month: oct,
        entries: e ?? entries,
        today: DateTime(2026, 10, 5),
        options: o,
      );

  test('default bill: month, day list, total and amount — no greeting', () {
    expect(bill(const BillOptions()), '''
October 2026

1 Oct – 1 L
2 Oct – 1½ L
3 Oct – no milk
4 Oct – 1 L

Total: 3½ L
Amount: ₹245''');
  });

  test('amount can be left out, so the milkman sees only litres', () {
    final text = bill(const BillOptions(amount: false));
    expect(text, isNot(contains('₹')));
    expect(text, contains('Total: 3½ L'));
  });

  test('without the day list, no-milk days are summarised', () {
    final text = bill(const BillOptions(dayList: false));
    expect(text, isNot(contains('1 Oct –')));
    expect(text, contains('No milk on: 3 Oct (1 day)'));
  });

  test('rate shows exceptions when the price varied', () {
    final text = bill(
      const BillOptions(rate: true, dayList: false),
      e: [
        got(1, 1000),
        got(2, 1000, rate: 7200),
        got(5, 1000, rate: 7200),
        got(6, 1000),
      ],
    );
    expect(text, contains('Rate: ₹70 per litre (₹72 on 2, 5 Oct)'));
    expect(text, contains('Amount: ₹284'));
  });

  test('everything off leaves just the month', () {
    expect(
      bill(
        const BillOptions(
          dayList: false,
          totalLitres: false,
          rate: false,
          amount: false,
          noMilkDays: false,
        ),
      ),
      'October 2026',
    );
  });

  test('two products are named in the day list', () {
    const both = Household(
      id: 'h',
      name: 'Home',
      products: [cow, curd],
      members: {'mom': 'Mom'},
    );
    final e = DayEntry(
      date: DateTime(2026, 10, 1),
      status: DayStatus.got,
      quantitiesMl: const {'cow': 1000, 'curd': 500},
      ratesPaise: const {'cow': 7000, 'curd': 12000},
      byUid: 'mom',
      at: DateTime(2026, 10, 1),
    );
    final text = bill(const BillOptions(), e: [e], h: both);
    expect(text, startsWith('October 2026\n'));
    expect(text, contains('1 Oct – Cow milk 1 L, Curd ½ L'));
    expect(text, contains('Amount: ₹130'));
  });

  test('today and tomorrow messages carry only the values', () {
    expect(
      todayMessage(household: home, entry: got(2, 1500), includePrice: false),
      'Fri, 2 Oct: 1½ L',
    );
    expect(
      todayMessage(household: home, entry: got(2, 1500), includePrice: true),
      'Fri, 2 Oct: 1½ L\nRate: ₹70 per litre',
    );
    expect(
      todayMessage(household: home, entry: skipped(3), includePrice: false),
      'Sat, 3 Oct: no milk',
    );
    expect(
      tomorrowMessage(
        household: home,
        tomorrow: DateTime(2026, 10, 3),
        quantitiesMl: const {'cow': 2000},
      ),
      'Tomorrow (Sat, 3 Oct): 2 L',
    );
    expect(
      tomorrowMessage(
        household: home,
        tomorrow: DateTime(2026, 10, 3),
        quantitiesMl: const {'cow': 0},
      ),
      'Tomorrow (Sat, 3 Oct): no milk',
    );
  });

  test('bill options survive being saved and loaded', () {
    const o = BillOptions(rate: true, amount: false);
    final back = BillOptions.fromJson(o.toJson());
    expect(back.rate, isTrue);
    expect(back.amount, isFalse);
    expect(back.dayList, isTrue);
  });

  test('going away message, for a range and a single day', () {
    expect(
      awayMessage(
        household: home,
        from: DateTime(2026, 10, 3),
        to: DateTime(2026, 10, 7),
      ),
      'No milk: Sat, 3 Oct – Wed, 7 Oct\nRestart: Thu, 8 Oct',
    );
    expect(
      awayMessage(
        household: home,
        from: DateTime(2026, 10, 31),
        to: DateTime(2026, 10, 31),
      ),
      'No milk: Sat, 31 Oct\nRestart: Sun, 1 Nov',
    );
  });

  test('no message has a greeting or sign-off', () {
    final all = [
      bill(const BillOptions()),
      todayMessage(household: home, entry: got(2, 1000), includePrice: true),
      tomorrowMessage(
        household: home,
        tomorrow: DateTime(2026, 10, 3),
        quantitiesMl: const {'cow': 1000},
      ),
      awayMessage(
        household: home,
        from: DateTime(2026, 10, 3),
        to: DateTime(2026, 10, 4),
      ),
    ];
    for (final m in all) {
      expect(
        m,
        isNot(
          matches(RegExp('Namaste|Ramesh|Please|Thank', caseSensitive: false)),
        ),
      );
    }
  });
}
