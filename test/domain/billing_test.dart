import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/billing.dart';
import 'package:milk_tracker/domain/models.dart';

DayEntry got(int day, int ml, int ratePaise, {int month = 10}) => DayEntry(
  date: DateTime(2026, month, day),
  status: DayStatus.got,
  quantitiesMl: {'cow': ml},
  ratesPaise: {'cow': ratePaise},
  byUid: 'mom',
  at: DateTime(2026, month, day, 7),
);

DayEntry skipped(int day) => DayEntry(
  date: DateTime(2026, 10, day),
  status: DayStatus.skipped,
  quantitiesMl: const {},
  ratesPaise: const {},
  byUid: 'dad',
  at: DateTime(2026, 10, day, 7),
);

void main() {
  const oct = (year: 2026, month: 10);

  test('totals litres and amount, counting skipped days separately', () {
    final s = summarizeMonth(
      month: oct,
      entries: [got(1, 1000, 7000), got(2, 1500, 7000), skipped(3)],
      today: DateTime(2026, 10, 4),
    );
    expect(s.totalMl, 2500);
    expect(s.amountPaise, 17500); // 2.5 L × ₹70
    expect(s.gotDays, 2);
    expect(s.skippedDays, 1);
    expect(s.missingDays, isEmpty);
  });

  test('each day is billed at the rate stored on it', () {
    final s = summarizeMonth(
      month: oct,
      entries: [got(1, 1000, 7000), got(2, 1000, 7200)],
      today: DateTime(2026, 10, 3),
    );
    expect(s.amountPaise, 14200);
  });

  test('rounds to the nearest paisa once, at the end', () {
    // 3 × 250 ml at ₹68.50/L = ₹51.375 -> ₹51.38
    final s = summarizeMonth(
      month: oct,
      entries: [got(1, 250, 6850), got(2, 250, 6850), got(3, 250, 6850)],
      today: DateTime(2026, 10, 4),
    );
    expect(s.amountPaise, 5138);
  });

  test('missing days are past days with no entry; today and future are not missing', () {
    final s = summarizeMonth(
      month: oct,
      entries: [got(1, 1000, 7000), skipped(3)],
      today: DateTime(2026, 10, 5),
    );
    expect(s.missingDays, [DateTime(2026, 10, 2), DateTime(2026, 10, 4)]);
  });

  test('ignores entries from other months', () {
    final s = summarizeMonth(
      month: oct,
      entries: [got(30, 1000, 7000, month: 9), got(1, 1000, 7000)],
      today: DateTime(2026, 10, 2),
    );
    expect(s.totalMl, 1000);
  });

  test('days before tracking started are not counted as missing', () {
    final s = summarizeMonth(
      month: oct,
      entries: [got(20, 1000, 7000)],
      today: DateTime(2026, 10, 23),
      trackingSince: DateTime(2026, 10, 20, 15, 30),
    );
    expect(s.missingDays, [DateTime(2026, 10, 21), DateTime(2026, 10, 22)]);
  });
}
