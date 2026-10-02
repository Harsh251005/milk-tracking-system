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

  test('default bill: greeting, day list, total and amount', () {
    expect(bill(const BillOptions()), '''
Namaste Ramesh,
Milk for October 2026:

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

  test('everything off leaves just the greeting and month', () {
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
      'Namaste Ramesh,\nMilk for October 2026:',
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
    expect(text, startsWith('Namaste,\n'));
    expect(text, contains('1 Oct – Cow milk 1 L, Curd ½ L'));
    expect(text, contains('Amount: ₹130'));
  });

  test('today and tomorrow messages', () {
    expect(
      todayMessage(household: home, entry: got(2, 1500), includePrice: false),
      'Namaste Ramesh,\nReceived 1½ L milk today (Fri, 2 Oct).\nThank you.',
    );
    expect(
      todayMessage(household: home, entry: got(2, 1500), includePrice: true),
      contains('Rate: ₹70 per litre'),
    );
    expect(
      todayMessage(household: home, entry: skipped(3), includePrice: false),
      'Namaste Ramesh,\nNo milk today (Sat, 3 Oct).',
    );
    expect(
      tomorrowMessage(
        household: home,
        tomorrow: DateTime(2026, 10, 3),
        quantitiesMl: const {'cow': 2000},
      ),
      'Namaste Ramesh,\nPlease send 2 L milk tomorrow (Sat, 3 Oct).',
    );
    expect(
      tomorrowMessage(
        household: home,
        tomorrow: DateTime(2026, 10, 3),
        quantitiesMl: const {'cow': 0},
      ),
      "Namaste Ramesh,\nPlease don't send milk tomorrow (Sat, 3 Oct).",
    );
  });

  test('bill options survive being saved and loaded', () {
    const o = BillOptions(rate: true, amount: false);
    final back = BillOptions.fromJson(o.toJson());
    expect(back.rate, isTrue);
    expect(back.amount, isFalse);
    expect(back.dayList, isTrue);
  });
}
