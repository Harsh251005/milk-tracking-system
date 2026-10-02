import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entries.dart';
import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/quantity_editor.dart';

/// Edits one day, or several at once (bulk). Returns true if anything changed.
Future<bool> showEntrySheet(
  BuildContext context, {
  required Household household,
  required List<DateTime> days,
  DayEntry? existing,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _EntrySheet(household: household, days: days, existing: existing),
  );
  return changed ?? false;
}

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({
    required this.household,
    required this.days,
    this.existing,
  });

  final Household household;
  final List<DateTime> days;
  final DayEntry? existing;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late Map<String, int> _draft = initialQuantities(
    widget.household,
    widget.existing,
  );

  bool get _single => widget.days.length == 1;

  Future<void> _apply(Future<void> Function() action) async {
    await action();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(milkRepositoryProvider);
    final t = Theme.of(context).textTheme;
    final total = _draft.values.fold(0, (a, b) => a + b);
    final now = DateTime.now();
    final count = widget.days.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _single
                ? DateFormat('EEEE, d MMMM').format(widget.days.single)
                : '$count days selected',
            style: t.headlineSmall,
          ),
          const SizedBox(height: 20),
          QuantityEditor(
            products: widget.household.products,
            quantitiesMl: _draft,
            onChanged: (d) => setState(() => _draft = d),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.colors.got),
            onPressed: total == 0
                ? null
                : () => _apply(
                    () => repo.saveEntries([
                      for (final d in widget.days)
                        gotEntry(
                          date: d,
                          household: widget.household,
                          quantitiesMl: _draft,
                          byUid: repo.currentUid,
                          now: now,
                        ),
                    ]),
                  ),
            icon: const Icon(Icons.check_rounded, size: 28),
            label: Text(
              _single
                  ? 'Got ${formatLitres(total)}'
                  : 'Got ${formatLitres(total)} each day',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _apply(
              () => repo.saveEntries([
                for (final d in widget.days)
                  skippedEntry(date: d, byUid: repo.currentUid, now: now),
              ]),
            ),
            icon: const Icon(Icons.block_rounded),
            label: Text(_single ? 'No milk this day' : 'No milk on these days'),
          ),
          if (!_single || widget.existing != null) ...[
            const SizedBox(height: 4),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _apply(() => repo.clearDays(widget.days)),
              child: Text(_single ? 'Clear this day' : 'Clear these days'),
            ),
          ],
        ],
      ),
    );
  }
}
