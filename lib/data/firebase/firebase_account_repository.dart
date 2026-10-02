import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/invite.dart';
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

  @override
  Future<Invite?> findInvite(String code) async {
    final snap = await _db
        .collection('joinCodes')
        .doc(code)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15), onTimeout: _noInternet);
    final data = snap.data();
    return data == null ? null : inviteFromMap(code, data);
  }

  @override
  Future<void> joinHousehold({
    required Invite invite,
    required String memberName,
  }) async {
    final household = _db.collection('households').doc(invite.householdId);
    final batch = _db.batch()
      // The rules check lastJoinCode against joinCodes/ to allow this.
      ..update(household, {
        'members.$uid': memberName,
        'lastJoinCode': invite.code,
      })
      ..set(_user, {'householdId': invite.householdId});
    await batch.commit().timeout(
      const Duration(seconds: 15),
      onTimeout: _noInternet,
    );
  }

  static Never _noInternet() => throw FirebaseException(
    plugin: 'cloud_firestore',
    code: 'unavailable',
    message: 'Joining needs internet.',
  );
}
