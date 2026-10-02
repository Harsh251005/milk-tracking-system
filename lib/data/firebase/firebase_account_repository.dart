import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models.dart';
import '../account_repository.dart';
import 'codec.dart';

class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository(this._db, {required this.uid});

  final FirebaseFirestore _db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  @override
  Stream<String?> watchHouseholdId() => _user
      .snapshots(includeMetadataChanges: true)
      // A cache miss isn't proof the user has no household; wait for the server.
      .where((s) => s.exists || !s.metadata.isFromCache)
      .map((s) => s.data()?['householdId'] as String?);

  @override
  Future<String> createHousehold({
    required String memberName,
    required Product product,
    String? milkmanName,
    String? milkmanPhone,
  }) async {
    final household = _db.collection('households').doc();
    final batch = _db.batch()
      ..set(household, {
        'name': 'Home',
        'members': {uid: memberName},
        'products': {product.id: productToMap(product)},
        'milkman': milkmanToMap(milkmanName, milkmanPhone),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(_user, {'householdId': household.id});
    // Applied to the local cache at once. Wait for the server so a rejected
    // write shows up as an error, but don't hang forever on a weak network:
    // after the timeout it stays queued and syncs later.
    await batch.commit().timeout(const Duration(seconds: 15), onTimeout: () {});
    return household.id;
  }
}
