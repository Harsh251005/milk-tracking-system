import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';
import '../data/backup.dart';
import '../data/firebase/firebase_account_repository.dart';
import '../data/firebase/firestore_milk_repository.dart';
import '../data/milk_repository.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'clock.dart';

// --- Session: who is this phone, and which household is it in? ------------

/// The signed-in account on this phone. Signs in anonymously on first
/// launch (no login screen). Follows sign-in changes, so restoring from a
/// Google backup switches every provider below to the restored account.
final signedInUidProvider = StreamProvider<String>((ref) async* {
  final auth = FirebaseAuth.instance;
  await for (final user in auth.authStateChanges()) {
    if (user == null) {
      await auth.signInAnonymously(); // the next event carries the new user
    } else {
      yield user.uid;
    }
  }
});

final backupProvider = Provider<Backup>((ref) => GoogleBackup());

/// Email this account is backed up to, or null if not backed up yet.
final backupEmailProvider = StreamProvider<String?>(
  (ref) => ref.watch(backupProvider).watchEmail(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => FirebaseAccountRepository(
    FirebaseFirestore.instance,
    uid: ref.watch(signedInUidProvider).requireValue,
  ),
);

/// Null until this phone has set up a household.
final householdIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(accountRepositoryProvider).watchHouseholdId(),
);

// --- Household data ---------------------------------------------------------

/// The one place that decides which backend the app uses. Only read once
/// the session is ready (see AppGate); tests override it.
final milkRepositoryProvider = Provider<MilkRepository>(
  (ref) => FirestoreMilkRepository(
    FirebaseFirestore.instance,
    currentUid: ref.watch(signedInUidProvider).requireValue,
    householdId: ref.watch(householdIdProvider).requireValue!,
  ),
);

/// Today's date, kept current across midnight and app resumes.
/// Tests override this with a fixed day.
final todayProvider = Provider<DateTime>(
  (ref) => ref.watch(currentDayProvider),
);

final householdProvider = StreamProvider<Household>(
  (ref) => ref.watch(milkRepositoryProvider).watchHousehold(),
);

final monthEntriesProvider = StreamProvider.family<List<DayEntry>, YearMonth>(
  (ref, month) => ref.watch(milkRepositoryProvider).watchMonth(month),
);

final monthPaymentProvider = StreamProvider.family<MonthPayment?, YearMonth>(
  (ref, month) => ref.watch(milkRepositoryProvider).watchPayment(month),
);
