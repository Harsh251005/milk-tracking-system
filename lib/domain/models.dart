/// Plain data types shared by every layer. No Flutter or Firebase imports.
///
/// Money is stored in paise and quantities in millilitres, both as ints,
/// so totals never pick up floating-point drift.
library;

enum DayStatus { got, skipped }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.ratePaise,
    required this.usualMl,
  });

  final String id;
  final String name;

  /// Price of one litre, in paise.
  final int ratePaise;

  /// Quantity prefilled each morning.
  final int usualMl;
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.products,
    required this.members,
    this.milkmanName,
    this.milkmanPhone,
  });

  final String id;
  final String name;
  final List<Product> products;

  /// uid -> display name ("Mom", "Dad").
  final Map<String, String> members;
  final String? milkmanName;
  final String? milkmanPhone;

  String memberName(String uid) => members[uid] ?? 'Someone';
}

/// One calendar day's record. A day with no entry is "not logged".
class DayEntry {
  const DayEntry({
    required this.date,
    required this.status,
    required this.quantitiesMl,
    required this.ratesPaise,
    required this.byUid,
    required this.at,
  });

  /// Local calendar date, time part zero.
  final DateTime date;
  final DayStatus status;

  /// productId -> millilitres received. Empty when skipped.
  final Map<String, int> quantitiesMl;

  /// productId -> rate per litre at the time of logging, so later rate
  /// changes never rewrite past bills.
  final Map<String, int> ratesPaise;
  final String byUid;
  final DateTime at;

  int get totalMl => quantitiesMl.values.fold(0, (a, b) => a + b);
}

class MonthPayment {
  const MonthPayment({
    required this.amountPaise,
    required this.byUid,
    required this.at,
  });

  final int amountPaise;
  final String byUid;
  final DateTime at;
}
