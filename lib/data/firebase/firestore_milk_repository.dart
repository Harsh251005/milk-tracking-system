import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../milk_repository.dart';
import 'codec.dart';

/// Firestore-backed household data. Every write is a plain set/update/delete
/// (no transactions), so it works offline and syncs when back online.
class FirestoreMilkRepository implements MilkRepository {
  FirestoreMilkRepository(
    this._db, {
    required this.currentUid,
    required this.householdId,
  });

  final FirebaseFirestore _db;
  final String householdId;
  final _writeErrors = StreamController<Object>.broadcast();

  @override
  Stream<Object> get writeErrors => _writeErrors.stream;

  @override
  final String currentUid;

  DocumentReference<Map<String, dynamic>> get _household =>
      _db.collection('households').doc(householdId);
  CollectionReference<Map<String, dynamic>> get _entries =>
      _household.collection('entries');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _household.collection('payments');

  @override
  Stream<Household> watchHousehold() => _household.snapshots().map((s) {
    final data = s.data();
    if (data == null) throw StateError('This household no longer exists.');
    return householdFromDoc(s.id, data);
  });

  @override
  Stream<List<DayEntry>> watchMonth(YearMonth month) => _entries
      .where(
        'date',
        isGreaterThanOrEqualTo: dayKey(DateTime(month.year, month.month)),
      )
      .where(
        'date',
        isLessThanOrEqualTo: dayKey(
          DateTime(
            month.year,
            month.month,
            daysInMonth(month.year, month.month),
          ),
        ),
      )
      .orderBy('date')
      .snapshots()
      .map((q) => [for (final d in q.docs) entryFromMap(d.data())]);

  @override
  Stream<MonthPayment?> watchPayment(YearMonth month) => _payments
      .doc(monthKey(month))
      .snapshots()
      .map((s) => s.data() == null ? null : paymentFromMap(s.data()!));

  @override
  Future<void> saveEntries(List<DayEntry> entries) {
    final batch = _db.batch();
    for (final e in entries) {
      batch.set(_entries.doc(dayKey(e.date)), entryToMap(e));
    }
    return _commit(batch);
  }

  @override
  Future<void> clearDays(List<DateTime> days) {
    final batch = _db.batch();
    for (final d in days) {
      batch.delete(_entries.doc(dayKey(d)));
    }
    return _commit(batch);
  }

  @override
  Future<void> updateProductRates(Map<String, int> ratesPaise) => _update({
    for (final e in ratesPaise.entries) 'products.${e.key}.ratePaise': e.value,
  });

  @override
  Future<void> saveProduct(Product product) =>
      _update({'products.${product.id}': productToMap(product)});

  @override
  Future<void> removeProduct(String productId) =>
      _update({'products.$productId': FieldValue.delete()});

  @override
  Future<void> setMilkman({String? name, String? phone}) =>
      _update({'milkman': milkmanToMap(name, phone)});

  @override
  Future<void> setMyName(String name) => _update({'members.$currentUid': name});

  @override
  Future<void> setPayment(YearMonth month, MonthPayment? payment) {
    final doc = _payments.doc(monthKey(month));
    return _offlineSafe(
      payment == null ? doc.delete() : doc.set(paymentToMap(payment)),
    );
  }

  Future<void> _update(Map<String, Object?> fields) =>
      _offlineSafe(_household.update(fields));

  Future<void> _commit(WriteBatch batch) => _offlineSafe(batch.commit());

  /// Firestore applies writes to the local cache immediately, but the
  /// returned future only completes once the server confirms, which never
  /// happens offline. So the UI doesn't wait; a rejected write is reported on
  /// [writeErrors] instead of being dropped.
  Future<void> _offlineSafe(Future<void> write) async {
    unawaited(write.catchError(_writeErrors.add));
  }
}
