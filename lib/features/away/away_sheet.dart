import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/dates.dart';
import '../../domain/entries.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/forms.dart';
import '../share/share_screen.dart';

/// "Going away": marks a run of days as no milk, then offers a ready
/// message for the milkman.
Future<void> showAwaySheet(BuildContext context, Household household) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AwaySheet(household: household),
    );

class _AwaySheet extends ConsumerStatefulWidget {
  const _AwaySheet({required this.household});

  final Household household;

  @override
  ConsumerState<_AwaySheet> createState() => _AwaySheetState();
}

class _AwaySheetState extends ConsumerState<_AwaySheet> {
  late final DateTime _today = ref.read(todayProvider);
  late DateTime _from = _today.add(const Duration(days: 1));
  late DateTime _to = _from;

  Future<void> _pick({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: from ? _today : _from,
      lastDate: _today.add(const Duration(days: 365)),
      helpText: from ? 'No milk from' : 'No milk until',
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _save({required bool message}) async {
    final repo = ref.read(milkRepositoryProvider);
    final now = DateTime.now();
    await repo.saveEntries([
      for (final d in daysBetween(_from, _to))
        skippedEntry(
          date: d,
          household: widget.household,
          byUid: repo.currentUid,
          now: now,
        ),
    ]);
    if (!mounted) return;
    final navigator = Navigator.of(context)..pop();
    if (message) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ShareScreen(kind: MessageKind.away, away: (from: _from, to: _to)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final days = daysBetween(_from, _to).length;
    final fmt = DateFormat('EEE, d MMM');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Going away?', style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Mark the days with no milk, all at once.',
            style: t.bodyLarge?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  date: _from,
                  onTap: () => _pick(from: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Until',
                  date: _to,
                  onTap: () => _pick(from: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.skippedSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              days == 1
                  ? 'No milk on ${fmt.format(_from)}.'
                  : 'No milk for $days days, ${fmt.format(_from)} to '
                        '${fmt.format(_to)}.',
              style: t.titleMedium,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _save(message: true),
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Mark days & message milkman'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _save(message: false),
            child: const Text('Only mark the days'),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        Material(
          color: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.colors.border, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(DateFormat('EEE').format(date), style: t.bodyMedium),
                  Text(
                    DateFormat('d MMM').format(date),
                    style: t.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
