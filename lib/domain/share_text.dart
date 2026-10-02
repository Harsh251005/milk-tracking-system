import 'package:intl/intl.dart';

import 'billing.dart';
import 'dates.dart';
import 'format.dart';
import 'models.dart';

/// Which parts of the monthly bill message to include.
class BillOptions {
  const BillOptions({
    this.dayList = true,
    this.totalLitres = true,
    this.rate = false,
    this.amount = true,
    this.noMilkDays = true,
  });

  final bool dayList;
  final bool totalLitres;
  final bool rate;
  final bool amount;
  final bool noMilkDays;

  BillOptions copyWith({
    bool? dayList,
    bool? totalLitres,
    bool? rate,
    bool? amount,
    bool? noMilkDays,
  }) => BillOptions(
    dayList: dayList ?? this.dayList,
    totalLitres: totalLitres ?? this.totalLitres,
    rate: rate ?? this.rate,
    amount: amount ?? this.amount,
    noMilkDays: noMilkDays ?? this.noMilkDays,
  );

  Map<String, bool> toJson() => {
    'dayList': dayList,
    'totalLitres': totalLitres,
    'rate': rate,
    'amount': amount,
    'noMilkDays': noMilkDays,
  };

  factory BillOptions.fromJson(Map<String, dynamic> j) => BillOptions(
    dayList: j['dayList'] as bool? ?? true,
    totalLitres: j['totalLitres'] as bool? ?? true,
    rate: j['rate'] as bool? ?? false,
    amount: j['amount'] as bool? ?? true,
    noMilkDays: j['noMilkDays'] as bool? ?? true,
  );
}

String _greeting(Household h) {
  final name = h.milkmanName?.trim() ?? '';
  return name.isEmpty ? 'Namaste,' : 'Namaste $name,';
}

String _day(DateTime d) => DateFormat('d MMM').format(d);
String _dayLong(DateTime d) => DateFormat('EEE, d MMM').format(d);

/// "Cow milk 1 L, Curd ½ L" — names only when there's more than one product.
String _quantities(Household h, Map<String, int> ml) {
  final parts = [
    for (final p in h.products)
      if ((ml[p.id] ?? 0) > 0)
        h.products.length > 1
            ? '${p.name} ${formatLitres(ml[p.id]!)}'
            : formatLitres(ml[p.id]!),
  ];
  // A product removed since keeps showing its quantity, unnamed.
  for (final e in ml.entries) {
    if (e.value > 0 && !h.products.any((p) => p.id == e.key)) {
      parts.add(formatLitres(e.value));
    }
  }
  return parts.join(', ');
}

/// "₹70 per litre", or "₹70 per litre (₹72 on 2, 5 Oct)" when it varied.
List<String> _rateLines(Household h, List<DayEntry> got) {
  final lines = <String>[];
  for (final p in h.products) {
    final daysByRate = <int, List<DateTime>>{};
    for (final e in got) {
      final rate = e.ratesPaise[p.id];
      if (rate != null && (e.quantitiesMl[p.id] ?? 0) > 0) {
        daysByRate.putIfAbsent(rate, () => []).add(e.date);
      }
    }
    if (daysByRate.isEmpty) continue;
    final byUse = daysByRate.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final main = byUse.first.key;
    final exceptions = [
      for (final r in byUse.skip(1))
        '${formatRupees(r.key)} on ${_dayNumbers(r.value)}',
    ];
    final label = h.products.length > 1 ? '${p.name}: ' : '';
    lines.add(
      '$label${formatRupees(main)} per litre'
      '${exceptions.isEmpty ? '' : ' (${exceptions.join('; ')})'}',
    );
  }
  return lines;
}

/// [2 Oct, 5 Oct] -> "2, 5 Oct".
String _dayNumbers(List<DateTime> days) {
  final sorted = [...days]..sort();
  return '${sorted.map((d) => d.day).join(', ')} '
      '${DateFormat('MMM').format(sorted.first)}';
}

String billMessage({
  required Household household,
  required YearMonth month,
  required List<DayEntry> entries,
  required DateTime today,
  required BillOptions options,
}) {
  final inMonth =
      entries
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final summary = summarizeMonth(
    month: month,
    entries: inMonth,
    today: today,
    trackingSince: household.startedOn,
  );
  final got = inMonth.where((e) => e.status == DayStatus.got).toList();
  final skipped = inMonth.where((e) => e.status == DayStatus.skipped).toList();
  final monthName = DateFormat('MMMM yyyy')
      .format(DateTime(month.year, month.month));

  final out = <String>[_greeting(household), 'Milk for $monthName:'];

  if (options.dayList && inMonth.isNotEmpty) {
    out.add('');
    for (final e in inMonth) {
      out.add(
        '${_day(e.date)} – '
        '${e.status == DayStatus.got ? _quantities(household, e.quantitiesMl) : 'no milk'}',
      );
    }
  }

  final totals = <String>[
    if (options.totalLitres) 'Total: ${formatLitres(summary.totalMl)}',
    if (options.rate)
      for (final line in _rateLines(household, got)) 'Rate: $line',
    // The day list already shows no-milk days; don't repeat them.
    if (options.noMilkDays && !options.dayList && skipped.isNotEmpty)
      'No milk on: ${_dayNumbers([for (final e in skipped) e.date])} '
          '(${skipped.length} ${skipped.length == 1 ? 'day' : 'days'})',
    if (options.amount) 'Amount: ${formatRupees(summary.amountPaise)}',
  ];
  if (totals.isNotEmpty) out.addAll(['', ...totals]);
  return out.join('\n');
}

String todayMessage({
  required Household household,
  required DayEntry entry,
  required bool includePrice,
}) {
  final when = 'today (${_dayLong(entry.date)})';
  if (entry.status == DayStatus.skipped) {
    return '${_greeting(household)}\nNo milk $when.';
  }
  final price = includePrice ? _rateLines(household, [entry]) : const [];
  return '${_greeting(household)}\n'
      'Received ${_quantities(household, entry.quantitiesMl)} milk $when.'
      '${price.isEmpty ? '' : '\nRate: ${price.join(', ')}'}\n'
      'Thank you.';
}

String tomorrowMessage({
  required Household household,
  required DateTime tomorrow,
  required Map<String, int> quantitiesMl,
}) {
  final when = 'tomorrow (${_dayLong(tomorrow)})';
  final total = quantitiesMl.values.fold(0, (a, b) => a + b);
  if (total == 0) {
    return "${_greeting(household)}\nPlease don't send milk $when.";
  }
  return '${_greeting(household)}\n'
      'Please send ${_quantities(household, quantitiesMl)} milk $when.';
}

String awayMessage({
  required Household household,
  required DateTime from,
  required DateTime to,
}) {
  final back = DateTime(to.year, to.month, to.day + 1);
  final when = isSameDay(from, to)
      ? 'on ${_dayLong(from)}'
      : 'from ${_dayLong(from)} to ${_dayLong(to)}';
  return '${_greeting(household)}\n'
      "We will be away. Please don't send milk $when.\n"
      'Please start again from ${_dayLong(back)}.';
}
