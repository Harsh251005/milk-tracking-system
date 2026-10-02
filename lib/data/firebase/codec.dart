import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/dates.dart';
import '../../domain/models.dart';

/// Firestore document <-> model conversion. Pure functions, unit-tested.
///
/// households/{id}:
///   members:  {uid: name}
///   products: {productId: {name, ratePaise, usualMl}}
///             (a map, not a list, so one price can be updated offline
///             without a read-modify-write transaction)
///   milkman:  {name, phone}
/// households/{id}/entries/{yyyy-MM-dd}
/// households/{id}/payments/{yyyy-MM}

Household householdFromDoc(String id, Map<String, dynamic> d) {
  // Product ids are time-based (see newProductId), so id order = creation order.
  final products =
      (d['products'] as Map<String, dynamic>? ?? {}).entries
          .map((e) => (e.key, e.value as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));
  final milkman = d['milkman'] as Map<String, dynamic>?;
  return Household(
    id: id,
    name: d['name'] as String? ?? 'Home',
    members: (d['members'] as Map<String, dynamic>? ?? {}).map(
      (uid, name) => MapEntry(uid, name as String),
    ),
    products: [
      for (final (pid, p) in products)
        Product(
          id: pid,
          name: p['name'] as String,
          ratePaise: (p['ratePaise'] as num).toInt(),
          usualMl: (p['usualMl'] as num).toInt(),
        ),
    ],
    milkmanName: milkman?['name'] as String?,
    milkmanPhone: milkman?['phone'] as String?,
    // createdAt is a server timestamp: null in the local copy until the
    // server confirms it, which only happens right after setup (= today).
    startedOn: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

Map<String, dynamic> productToMap(Product p) => {
  'name': p.name,
  'ratePaise': p.ratePaise,
  'usualMl': p.usualMl,
};

Map<String, dynamic> milkmanToMap(String? name, String? phone) => {
  if (name != null && name.isNotEmpty) 'name': name,
  if (phone != null && phone.isNotEmpty) 'phone': phone,
};

Map<String, dynamic> entryToMap(DayEntry e) => {
  'date': dayKey(e.date),
  'status': e.status.name,
  'quantitiesMl': e.quantitiesMl,
  'ratesPaise': e.ratesPaise,
  'byUid': e.byUid,
  'at': Timestamp.fromDate(e.at),
};

DayEntry entryFromMap(Map<String, dynamic> d) => DayEntry(
  date: DateTime.parse(d['date'] as String),
  status: DayStatus.values.byName(d['status'] as String),
  quantitiesMl: _intMap(d['quantitiesMl']),
  ratesPaise: _intMap(d['ratesPaise']),
  byUid: d['byUid'] as String,
  at: (d['at'] as Timestamp).toDate(),
);

Map<String, dynamic> paymentToMap(MonthPayment p) => {
  'amountPaise': p.amountPaise,
  'byUid': p.byUid,
  'at': Timestamp.fromDate(p.at),
};

MonthPayment paymentFromMap(Map<String, dynamic> d) => MonthPayment(
  amountPaise: (d['amountPaise'] as num).toInt(),
  byUid: d['byUid'] as String,
  at: (d['at'] as Timestamp).toDate(),
);

String monthKey(YearMonth m) =>
    '${m.year}-${m.month.toString().padLeft(2, '0')}';

Map<String, int> _intMap(Object? raw) => (raw as Map<String, dynamic>? ?? {})
    .map((k, v) => MapEntry(k, (v as num).toInt()));
