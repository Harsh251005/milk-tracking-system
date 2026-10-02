import '../domain/dates.dart';
import '../domain/models.dart';

/// Everything the screens need from storage. Screens depend only on this
/// interface, so the backend (in-memory now, Firestore from M3) can change
/// without touching UI code.
abstract interface class MilkRepository {
  /// The signed-in member on this phone.
  String get currentUid;

  /// Writes return before the server confirms (so the app works offline).
  /// A write the server later rejects is reported here.
  Stream<Object> get writeErrors;

  Stream<Household> watchHousehold();

  Stream<List<DayEntry>> watchMonth(YearMonth month);

  Stream<MonthPayment?> watchPayment(YearMonth month);

  /// Insert or replace entries, keyed by date.
  Future<void> saveEntries(List<DayEntry> entries);

  Future<void> clearDays(List<DateTime> days);

  /// Changes saved prices from now on. Past entries keep their own rates.
  Future<void> updateProductRates(Map<String, int> ratesPaise);

  /// Adds the product, or replaces the one with the same id.
  Future<void> saveProduct(Product product);

  /// Past entries keep their quantities and prices for this product.
  Future<void> removeProduct(String productId);

  Future<void> setMilkman({String? name, String? phone});

  /// Display name of the member on this phone.
  Future<void> setMyName(String name);

  /// Pass null to mark the month unpaid again.
  Future<void> setPayment(YearMonth month, MonthPayment? payment);
}
