import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entries.dart';
import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../domain/rates.dart';
import '../../state/providers.dart';

enum RateChoice { onlyTheseDays, fromNowOn, keepSaved }

/// Saves "got milk" for [days]. If a price differs from the saved one, asks
/// which to use first. Returns false if the person backed out of that question.
Future<bool> logGot(
  BuildContext context,
  WidgetRef ref, {
  required Household household,
  required List<DateTime> days,
  required Map<String, int> quantitiesMl,
  required Map<String, int> ratesPaise,
}) async {
  final repo = ref.read(milkRepositoryProvider);
  var rates = ratesPaise;

  final changes = rateChanges(household, quantitiesMl, ratesPaise);
  if (changes.isNotEmpty) {
    final choice = await showRateChoiceDialog(
      context,
      changes: changes,
      dayCount: days.length,
    );
    switch (choice) {
      case null:
        return false;
      case RateChoice.keepSaved:
        rates = savedRates(household);
      case RateChoice.fromNowOn:
        await repo.updateProductRates({
          for (final c in changes) c.product.id: c.newRatePaise,
        });
      case RateChoice.onlyTheseDays:
        break;
    }
  }

  final now = DateTime.now();
  await repo.saveEntries([
    for (final d in days)
      gotEntry(
        date: d,
        household: household,
        quantitiesMl: quantitiesMl,
        ratesPaise: rates,
        byUid: repo.currentUid,
        now: now,
      ),
  ]);
  return true;
}

Future<RateChoice?> showRateChoiceDialog(
  BuildContext context, {
  required List<RateChange> changes,
  required int dayCount,
}) => showDialog<RateChoice>(
  context: context,
  builder: (_) => _RateChoiceDialog(changes: changes, dayCount: dayCount),
);

class _RateChoiceDialog extends StatelessWidget {
  const _RateChoiceDialog({required this.changes, required this.dayCount});

  final List<RateChange> changes;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final single = changes.length == 1 ? changes.single : null;
    final dayWord = dayCount == 1 ? 'this day' : 'these $dayCount days';

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.currency_rupee_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'The price is different',
              textAlign: TextAlign.center,
              style: t.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final c in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${changes.length > 1 ? '${c.product.name}: ' : ''}'
                  'usually ${formatRupees(c.product.ratePaise)} per litre, '
                  'now ${formatRupees(c.newRatePaise)}.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Days already logged keep their own price.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(RateChoice.onlyTheseDays),
              child: Text(
                single == null
                    ? 'New price only for $dayWord'
                    : '${formatRupees(single.newRatePaise)} only for $dayWord',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(RateChoice.fromNowOn),
              child: Text(
                single == null
                    ? 'Use new price from now on'
                    : 'Use ${formatRupees(single.newRatePaise)} from now on',
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(RateChoice.keepSaved),
              child: Text(
                single == null
                    ? 'Keep usual price'
                    : 'Keep ${formatRupees(single.product.ratePaise)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
