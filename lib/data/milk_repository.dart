import '../domain/dates.dart';
import '../domain/models.dart';

/// Everything the screens need from storage. Screens depend only on this
/// interface, so the backend (in-memory now, Firestore from M3) can change
/// without touching UI code.
abstract interface class MilkRepository {
  /// The signed-in member on this phone.
  String get currentUid;

  Stream<Household> watchHousehold();

  Stream<List<DayEntry>> watchMonth(YearMonth month);

  Stream<MonthPayment?> watchPayment(YearMonth month);

  /// Insert or replace entries, keyed by date.
  Future<void> saveEntries(List<DayEntry> entries);

  Future<void> clearDays(List<DateTime> days);

  /// Pass null to mark the month unpaid again.
  Future<void> setPayment(YearMonth month, MonthPayment? payment);
}
