import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/billing.dart';
import '../../domain/dates.dart';
import '../../domain/entries.dart';
import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/quantity_editor.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key, required this.onOpenMonth});

  final VoidCallback onOpenMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return AsyncView(
      value: ref.watch(householdProvider),
      builder: (household) => AsyncView(
        value: ref.watch(monthEntriesProvider(monthOf(today))),
        builder: (entries) => _TodayBody(
          household: household,
          entries: entries,
          today: today,
          onOpenMonth: onOpenMonth,
        ),
      ),
    );
  }
}

class _TodayBody extends ConsumerStatefulWidget {
  const _TodayBody({
    required this.household,
    required this.entries,
    required this.today,
    required this.onOpenMonth,
  });

  final Household household;
  final List<DayEntry> entries;
  final DateTime today;
  final VoidCallback onOpenMonth;

  @override
  ConsumerState<_TodayBody> createState() => _TodayBodyState();
}

class _TodayBodyState extends ConsumerState<_TodayBody> {
  bool _editing = false;
  Map<String, int>? _draft;

  DayEntry? get _entry =>
      widget.entries.where((e) => isSameDay(e.date, widget.today)).firstOrNull;

  Future<void> _save(DayEntry entry) async {
    HapticFeedback.mediumImpact();
    await ref.read(milkRepositoryProvider).saveEntries([entry]);
    if (mounted) setState(() => _editing = false);
  }

  void _logGot() {
    final repo = ref.read(milkRepositoryProvider);
    _save(
      gotEntry(
        date: widget.today,
        household: widget.household,
        quantitiesMl: _draft!,
        byUid: repo.currentUid,
        now: DateTime.now(),
      ),
    );
  }

  void _logSkipped() {
    final repo = ref.read(milkRepositoryProvider);
    _save(
      skippedEntry(
        date: widget.today,
        byUid: repo.currentUid,
        now: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final showEditor = entry == null || _editing;
    _draft ??= initialQuantities(widget.household, entry);
    final summary = summarizeMonth(
      month: monthOf(widget.today),
      entries: widget.entries,
      today: widget.today,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _Header(today: widget.today),
        const SizedBox(height: 20),
        if (showEditor)
          _LogCard(
            household: widget.household,
            draft: _draft!,
            onDraftChanged: (d) => setState(() => _draft = d),
            onGot: _logGot,
            onSkipped: _logSkipped,
            onCancel: entry == null
                ? null
                : () => setState(() => _editing = false),
          )
        else
          _LoggedCard(
            entry: entry,
            household: widget.household,
            currentUid: ref.read(milkRepositoryProvider).currentUid,
            onChange: () => setState(() {
              _editing = true;
              _draft = initialQuantities(widget.household, entry);
            }),
          ),
        const SizedBox(height: 16),
        _MonthSoFar(
          summary: summary,
          today: widget.today,
          onOpenMonth: widget.onOpenMonth,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('EEEE').format(today), style: t.headlineMedium),
        Text(
          DateFormat('d MMMM').format(today),
          style: t.titleMedium?.copyWith(color: context.colors.muted),
        ),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.household,
    required this.draft,
    required this.onDraftChanged,
    required this.onGot,
    required this.onSkipped,
    required this.onCancel,
  });

  final Household household;
  final Map<String, int> draft;
  final ValueChanged<Map<String, int>> onDraftChanged;
  final VoidCallback onGot;
  final VoidCallback onSkipped;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final total = draft.values.fold(0, (a, b) => a + b);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How much milk came today?',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: 16),
          QuantityEditor(
            products: household.products,
            quantitiesMl: draft,
            onChanged: onDraftChanged,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: context.colors.got),
            onPressed: total > 0 ? onGot : null,
            icon: const Icon(Icons.check_rounded, size: 28),
            label: Text('Got ${formatLitres(total)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSkipped,
            icon: const Icon(Icons.block_rounded),
            label: const Text('No milk today'),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 4),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ],
      ),
    );
  }
}

class _LoggedCard extends StatelessWidget {
  const _LoggedCard({
    required this.entry,
    required this.household,
    required this.currentUid,
    required this.onChange,
  });

  final DayEntry entry;
  final Household household;
  final String currentUid;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final got = entry.status == DayStatus.got;
    final accent = got ? context.colors.got : context.colors.skipped;
    final who = entry.byUid == currentUid
        ? 'you'
        : household.memberName(entry.byUid);
    final when = DateFormat('h:mm a').format(entry.at).toLowerCase();

    return SectionCard(
      color: got ? context.colors.gotSoft : context.colors.skippedSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: accent,
                child: Icon(
                  got ? Icons.check_rounded : Icons.block_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      got
                          ? '${formatLitres(entry.totalMl)} received'
                          : 'No milk today',
                      style: t.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${got ? 'Logged' : 'Marked'} by $who · $when',
                      style: t.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (got && household.products.length > 1) ...[
            const SizedBox(height: 12),
            for (final p in household.products)
              if ((entry.quantitiesMl[p.id] ?? 0) > 0)
                Text(
                  '${p.name}: ${formatLitres(entry.quantitiesMl[p.id]!)}',
                  style: t.bodyLarge,
                ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: const Text('Change'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSoFar extends StatelessWidget {
  const _MonthSoFar({
    required this.summary,
    required this.today,
    required this.onOpenMonth,
  });

  final MonthSummary summary;
  final DateTime today;
  final VoidCallback onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final missing = summary.missingDays.length;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('MMMM').format(today)} so far',
                  style: t.titleLarge,
                ),
              ),
              TextButton(
                onPressed: onOpenMonth,
                child: const Text('See month'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatTile(value: formatLitres(summary.totalMl), label: 'Milk'),
              StatTile(value: formatRupees(summary.amountPaise), label: 'Bill'),
              StatTile(value: '${summary.skippedDays}', label: 'No milk'),
            ],
          ),
          if (missing > 0) ...[
            const SizedBox(height: 16),
            Material(
              color: context.colors.missingSoft,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onOpenMonth,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: context.colors.missing,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          missing == 1
                              ? '1 day not logged yet'
                              : '$missing days not logged yet',
                          style: t.titleMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.missing,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
