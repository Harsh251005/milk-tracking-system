import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory_milk_repository.dart';
import '../data/milk_repository.dart';
import '../domain/dates.dart';
import '../domain/models.dart';

/// The one place that decides which backend the app uses.
final milkRepositoryProvider = Provider<MilkRepository>(
  (ref) => MemoryMilkRepository.sample(today: DateTime.now()),
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
