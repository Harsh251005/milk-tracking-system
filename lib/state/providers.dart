import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';
import '../data/firebase/firebase_account_repository.dart';
import '../data/firebase/firestore_milk_repository.dart';
import '../data/milk_repository.dart';
import '../domain/dates.dart';
import '../domain/models.dart';

// --- Session: who is this phone, and which household is it in? ------------

/// Signs in anonymously on first launch; the account then persists on the
/// phone. No login screen, no password.
final signedInUidProvider = FutureProvider<String>((ref) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
  return user.uid;
});

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

/// Read once per app start; good enough until the app runs past midnight,
/// which M7's reminder work will handle.
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

final householdProvider = StreamProvider<Household>(
  (ref) => ref.watch(milkRepositoryProvider).watchHousehold(),
);

final monthEntriesProvider = StreamProvider.family<List<DayEntry>, YearMonth>(
  (ref, month) => ref.watch(milkRepositoryProvider).watchMonth(month),
);

final monthPaymentProvider = StreamProvider.family<MonthPayment?, YearMonth>(
  (ref, month) => ref.watch(milkRepositoryProvider).watchPayment(month),
);
