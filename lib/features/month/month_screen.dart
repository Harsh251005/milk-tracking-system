import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/billing.dart';
import '../../domain/dates.dart';
import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';
import 'calendar_grid.dart';
import 'entry_sheet.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  late YearMonth _month = monthOf(ref.read(todayProvider));
  final _selected = <DateTime>{};

  bool get _selecting => _selected.isNotEmpty;

  void _changeMonth(int delta) => setState(() {
    _month = addMonths(_month, delta);
    _selected.clear();
  });

  void _toggle(DateTime day) {
    HapticFeedback.selectionClick();
    setState(
      () =>
          _selected.contains(day) ? _selected.remove(day) : _selected.add(day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    return AsyncView(
      value: ref.watch(householdProvider),
      builder: (household) => AsyncView(
        value: ref.watch(monthEntriesProvider(_month)),
        builder: (entries) => AsyncView(
          value: ref.watch(monthPaymentProvider(_month)),
          builder: (payment) =>
              _build(context, household, entries, payment, today),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context,
    Household household,
    List<DayEntry> entries,
    MonthPayment? payment,
    DateTime today,
  ) {
    final summary = summarizeMonth(
      month: _month,
      entries: entries,
      today: today,
      trackingSince: household.startedOn,
    );
    final byDay = {for (final e in entries) dayKey(e.date): e};
    final isCurrent = _month == monthOf(today);

    return Column(
      children: [
        _MonthSwitcher(
          month: _month,
          canGoForward: !isCurrent,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _SummaryCard(
                summary: summary,
                payment: payment,
                household: household,
                isCurrentMonth: isCurrent,
              ),
              const SizedBox(height: 12),
              SectionCard(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                child: CalendarGrid(
                  month: _month,
                  today: today,
                  trackingSince: household.startedOn,
                  entriesByDay: byDay,
                  selected: _selected,
                  onTap: (day) {
                    if (_selecting) return _toggle(day);
                    showEntrySheet(
                      context,
                      household: household,
                      days: [day],
                      existing: byDay[dayKey(day)],
                    );
                  },
                  onLongPress: _toggle,
                ),
              ),
              const SizedBox(height: 12),
              const _Legend(),
              if (!_selecting)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tip: press and hold a day to select several at once.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.colors.muted),
                  ),
                ),
            ],
          ),
        ),
        if (_selecting)
          _SelectionBar(
            count: _selected.length,
            onCancel: () => setState(_selected.clear),
            onEdit: () async {
              final days = _selected.toList()..sort();
              final changed = await showEntrySheet(
                context,
                household: household,
                days: days,
              );
              if (changed && mounted) setState(_selected.clear);
            },
          )
        else
          _PaymentBar(month: _month, summary: summary, payment: payment),
      ],
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final YearMonth month;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          IconButton(
            iconSize: 32,
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(DateTime(month.year, month.month)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            iconSize: 32,
            tooltip: 'Next month',
            onPressed: canGoForward ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.payment,
    required this.household,
    required this.isCurrentMonth,
  });

  final MonthSummary summary;
  final MonthPayment? payment;
  final Household household;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final paid = payment;
    final (Color bg, Color fg, IconData icon, String text) = switch (paid) {
      MonthPayment p => (
        context.colors.gotSoft,
        context.colors.got,
        Icons.verified_rounded,
        'Paid ${formatRupees(p.amountPaise)} on ${DateFormat('d MMM').format(p.at)} · ${household.memberName(p.byUid)}',
      ),
      null when isCurrentMonth => (
        context.colors.skippedSoft,
        context.colors.muted,
        Icons.schedule_rounded,
        'Bill so far — month not over yet',
      ),
      null => (
        context.colors.missingSoft,
        context.colors.missing,
        Icons.payments_rounded,
        'Not paid yet',
      ),
    };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatTile(value: formatLitres(summary.totalMl), label: 'Milk'),
              StatTile(value: formatRupees(summary.amountPaise), label: 'Bill'),
              StatTile(value: '${summary.skippedDays}', label: 'No milk'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(c.gotSoft, 'Got milk'),
        item(c.skippedSoft, 'No milk'),
        item(c.missingSoft, 'Not logged'),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: child,
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onEdit,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _BottomBar(
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel',
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              count == 1 ? '1 day selected' : '$count days selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 56)),
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _PaymentBar extends ConsumerWidget {
  const _PaymentBar({
    required this.month,
    required this.summary,
    required this.payment,
  });

  final YearMonth month;
  final MonthSummary summary;
  final MonthPayment? payment;

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(milkRepositoryProvider);
    final monthName = DateFormat('MMMM')
        .format(DateTime(month.year, month.month));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark $monthName as paid?'),
        content: Text(
          'You paid the milkman ${formatRupees(summary.amountPaise)} for ${formatLitres(summary.totalMl)}.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, paid'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.setPayment(
      month,
      MonthPayment(
        amountPaise: summary.amountPaise,
        byUid: repo.currentUid,
        at: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
      onPressed: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('WhatsApp sharing comes in a later update.'),
          ),
        ),
      icon: const Icon(Icons.share_rounded),
      label: const Text('Share'),
    );

    if (payment != null) {
      return _BottomBar(
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () =>
                    ref.read(milkRepositoryProvider).setPayment(month, null),
                child: const Text('Mark as not paid'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: share),
          ],
        ),
      );
    }
    return _BottomBar(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
              onPressed: summary.amountPaise > 0
                  ? () => _markPaid(context, ref)
                  : null,
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Mark as paid'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: share),
        ],
      ),
    );
  }
}
