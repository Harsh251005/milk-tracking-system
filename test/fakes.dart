import 'package:milk_tracker/data/account_repository.dart';
import 'package:milk_tracker/domain/invite.dart';
import 'package:milk_tracker/domain/models.dart';

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.invites = const {}});

  /// Codes the fake "server" knows about.
  final Map<String, Invite> invites;

  ({String name, Product product, String? milkmanName, String? phone})? created;
  ({Invite invite, String name})? joined;

  @override
  Stream<String?> watchHouseholdId() => Stream.value(null);

  @override
  Future<String> createHousehold({
    required String memberName,
    required Product product,
    String? milkmanName,
    String? milkmanPhone,
  }) async {
    created = (
      name: memberName,
      product: product,
      milkmanName: milkmanName,
      phone: milkmanPhone,
    );
    return 'h1';
  }

  @override
  Future<Invite?> findInvite(String code) async => invites[code];

  @override
  Future<void> joinHousehold({
    required Invite invite,
    required String memberName,
  }) async {
    joined = (invite: invite, name: memberName);
  }
}
