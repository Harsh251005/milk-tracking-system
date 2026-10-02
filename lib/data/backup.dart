import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Recovery: tie this phone's account to a Google account, so a new or
/// reset phone can get back into the same household.
abstract interface class Backup {
  /// The Google email this account is backed up to, or null.
  Stream<String?> watchEmail();

  /// Links the current account to a Google account the person picks.
  /// Returns the email. Throws [BackupException] with a plain message.
  Future<String> backUp();

  /// Signs in to the account previously backed up to a Google account.
  Future<void> restore();
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleBackup implements Backup {
  final _auth = FirebaseAuth.instance;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= GoogleSignIn.instance.initialize();

  Future<AuthCredential?> _pickAccount() async {
    await _init();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw BackupException("Couldn't open Google sign-in (${e.code.name}).");
    }
  }

  @override
  Stream<String?> watchEmail() => _auth.userChanges().map(
    (u) => u?.providerData
        .where((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID)
        .map((p) => p.email)
        .firstOrNull,
  );

  @override
  Future<String> backUp() async {
    final credential = await _pickAccount();
    if (credential == null) throw const BackupException('Backup cancelled.');
    try {
      final result = await _auth.currentUser!.linkWithCredential(credential);
      return result.user?.email ??
          result.user?.providerData.firstOrNull?.email ??
          'your Google account';
    } on FirebaseAuthException catch (e) {
      throw BackupException(switch (e.code) {
        'credential-already-in-use' =>
          'That Google account already backs up another Milk Tracker. '
              'Pick a different account.',
        'provider-already-linked' => 'This phone is already backed up.',
        'network-request-failed' => 'Backing up needs internet.',
        _ => "Couldn't back up (${e.code}).",
      });
    }
  }

  @override
  Future<void> restore() async {
    final credential = await _pickAccount();
    if (credential == null) throw const BackupException('Restore cancelled.');
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw BackupException(switch (e.code) {
        'network-request-failed' => 'Restoring needs internet.',
        _ => "Couldn't restore (${e.code}).",
      });
    }
  }
}
