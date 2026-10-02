import 'dart:async';

import '../domain/billing.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'milk_repository.dart';

/// In-memory store with realistic sample data. Used for UI review (M1) and
/// widget tests; replaced by the Firestore repository in M3.
class MemoryMilkRepository implements MilkRepository {
  MemoryMilkRepository._(this._household);

  factory MemoryMilkRepository.sample({required DateTime today}) {
    const cow = Product(
      id: 'cow',
      name: 'Cow milk',
      ratePaise: 7000,
      usualMl: 1000,
    );
    final repo = MemoryMilkRepository._(
      const Household(
        id: 'sample',
        name: 'Home',
        products: [cow],
        members: {'mom': 'Mom', 'dad': 'Dad'},
        milkmanName: 'Ramesh bhaiya',
        milkmanPhone: '919800000000',
      ),
    );
    repo._seed(today, cow);
    return repo;
  }

  Household _household;
  final _entries = <String, DayEntry>{};
  final _payments = <String, MonthPayment>{};
  final _changes = StreamController<void>.broadcast();

  @override
  String get currentUid => 'mom';

  void _seed(DateTime today, Product cow) {
    final t = dateOnly(today);
    final thisMonth = monthOf(t);
    final lastMonth = addMonths(thisMonth, -1);

    // Last month: fully logged and paid.
    for (var d = 1; d <= daysInMonth(lastMonth.year, lastMonth.month); d++) {
      final date = DateTime(lastMonth.year, lastMonth.month, d);
      _put(_sampleEntry(date, cow, skip: d == 9 || d == 23, extra: d % 7 == 0));
    }
    final lastSummary = summarizeMonth(
      month: lastMonth,
      entries: _entries.values,
      today: t,
    );
    _payments[_monthKey(lastMonth)] = MonthPayment(
      amountPaise: lastSummary.amountPaise,
      byUid: 'dad',
      at: DateTime(thisMonth.year, thisMonth.month, 1, 18),
    );

    // This month up to yesterday, with one day left unlogged.
    for (var d = 1; d < t.day; d++) {
      if (d == t.day - 2) continue;
      final date = DateTime(t.year, t.month, d);
      _put(_sampleEntry(date, cow, skip: d == 4, extra: d % 6 == 0));
    }
  }

  DayEntry _sampleEntry(
    DateTime date,
    Product p, {
    required bool skip,
    required bool extra,
  }) => DayEntry(
    date: date,
    status: skip ? DayStatus.skipped : DayStatus.got,
    quantitiesMl: skip ? const {} : {p.id: extra ? 1500 : p.usualMl},
    ratesPaise: skip ? const {} : {p.id: p.ratePaise},
    byUid: date.day.isEven ? 'dad' : 'mom',
    at: date.add(const Duration(hours: 7, minutes: 40)),
  );

  void _put(DayEntry e) => _entries[dayKey(e.date)] = e;

  static String _monthKey(YearMonth m) =>
      '${m.year}-${m.month.toString().padLeft(2, '0')}';

  /// Emits the current value now, then again after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<Household> watchHousehold() => _watch(() => _household);

  @override
  Stream<List<DayEntry>> watchMonth(YearMonth month) => _watch(
    () =>
        _entries.values
            .where(
              (e) => e.date.year == month.year && e.date.month == month.month,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
  );

  @override
  Stream<MonthPayment?> watchPayment(YearMonth month) =>
      _watch(() => _payments[_monthKey(month)]);

  @override
  Future<void> saveEntries(List<DayEntry> entries) async {
    entries.forEach(_put);
    _changes.add(null);
  }

  @override
  Future<void> clearDays(List<DateTime> days) async {
    for (final d in days) {
      _entries.remove(dayKey(d));
    }
    _changes.add(null);
  }

  @override
  Future<void> updateProductRates(Map<String, int> ratesPaise) async {
    final h = _household;
    _household = Household(
      id: h.id,
      name: h.name,
      members: h.members,
      milkmanName: h.milkmanName,
      milkmanPhone: h.milkmanPhone,
      products: [
        for (final p in h.products)
          Product(
            id: p.id,
            name: p.name,
            ratePaise: ratesPaise[p.id] ?? p.ratePaise,
            usualMl: p.usualMl,
          ),
      ],
    );
    _changes.add(null);
  }

  @override
  Future<void> setPayment(YearMonth month, MonthPayment? payment) async {
    if (payment == null) {
      _payments.remove(_monthKey(month));
    } else {
      _payments[_monthKey(month)] = payment;
    }
    _changes.add(null);
  }

  /// Test helper.
  void replaceHousehold(Household h) {
    _household = h;
    _changes.add(null);
  }
}
