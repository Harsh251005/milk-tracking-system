import '../domain/invite.dart';
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

  /// Looks a code up on the server. Null if no such code exists.
  Future<Invite?> findInvite(String code);

  /// Adds this phone to the invite's household under [memberName].
  Future<void> joinHousehold({
    required Invite invite,
    required String memberName,
  });
}
