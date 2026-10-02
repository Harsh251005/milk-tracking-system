import '../domain/models.dart';

/// Which household this phone belongs to, and creating one on first run.
abstract interface class AccountRepository {
  /// Emits null until this phone has set up (or, from M5, joined) a household.
  Stream<String?> watchHouseholdId();

  /// Creates a household with this phone as its first member.
  Future<String> createHousehold({
    required String memberName,
    required Product product,
    String? milkmanName,
    String? milkmanPhone,
  });
}
