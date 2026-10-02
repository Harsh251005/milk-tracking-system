/// Plain data types shared by every layer. No Flutter or Firebase imports.
///
/// Money is stored in paise and quantities in millilitres, both as ints,
/// so totals never pick up floating-point drift.
library;

enum DayStatus { got, skipped }

/// Time-based, so sorting ids gives creation order.
String newProductId([DateTime? now]) =>
    'p${(now ?? DateTime.now()).millisecondsSinceEpoch}';

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

  Product copyWith({String? name, int? ratePaise, int? usualMl}) => Product(
    id: id,
    name: name ?? this.name,
    ratePaise: ratePaise ?? this.ratePaise,
    usualMl: usualMl ?? this.usualMl,
  );
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.products,
    required this.members,
    this.milkmanName,
    this.milkmanPhone,
    this.startedOn,
  });

  final String id;
  final String name;

  /// Day the household was set up. Earlier days aren't flagged "not logged".
  /// Null means no limit.
  final DateTime? startedOn;
  final List<Product> products;

  /// uid -> display name ("Mom", "Dad").
  final Map<String, String> members;
  final String? milkmanName;
  final String? milkmanPhone;

  String memberName(String uid) => members[uid] ?? 'Someone';

  /// Who logged [e]: their current name, or the name saved on the entry if
  /// that phone has since been removed from the family.
  String loggedBy(DayEntry e) => members[e.byUid] ?? e.byName ?? 'Someone';
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
    this.byName,
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

  /// Logger's display name when it was logged; outlives their membership.
  final String? byName;
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
