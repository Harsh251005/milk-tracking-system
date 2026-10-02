import 'package:flutter/material.dart';

import '../../domain/billing.dart';
import '../../domain/dates.dart';
import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../ui/theme.dart';

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Monday-first month grid. Each cell shows the litres, a dash for
/// "no milk", or an amber tint for past days nobody logged.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.today,
    required this.entriesByDay,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.trackingSince,
  });

  final DateTime? trackingSince;
  final YearMonth month;
  final DateTime today;
  final Map<String, DayEntry> entriesByDay;
  final Set<DateTime> selected;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  @override
  Widget build(BuildContext context) {
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final days = daysInMonth(month.year, month.month);
    final muted = context.colors.muted;

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            // Grow with the phone's text size (parents often enlarge it).
            mainAxisExtent: MediaQuery.textScalerOf(context)
                .scale(58)
                .clamp(58, 96),
          ),
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                date: DateTime(month.year, month.month, d),
                today: today,
                trackingSince: trackingSince,
                entry:
                    entriesByDay[dayKey(DateTime(month.year, month.month, d))],
                selected: selected.contains(
                  DateTime(month.year, month.month, d),
                ),
                onTap: onTap,
                onLongPress: onLongPress,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.trackingSince,
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime date;
  final DateTime today;
  final DateTime? trackingSince;
  final DayEntry? entry;
  final bool selected;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isFuture = date.isAfter(today);
    final isToday = isSameDay(date, today);
    final e = entry;

    final (Color bg, String main) = switch (e?.status) {
      _ when selected => (scheme.primary, e == null ? '' : _mainText(e)),
      DayStatus.got => (c.gotSoft, formatQty(e!.totalMl)),
      DayStatus.skipped => (c.skippedSoft, '—'),
      null
          when !isExpectedDay(
            date,
            today: today,
            trackingSince: trackingSince,
          ) =>
        (Colors.transparent, ''),
      null => (c.missingSoft, ''),
    };
    final fg = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: !isFuture || e != null,
      label: _semanticLabel(e),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isToday && !selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Future days open only if something is planned on them
          // (e.g. "going away"), so it can be undone.
          onTap: isFuture && e == null ? null : () => onTap(date),
          onLongPress: isFuture && e == null ? null : () => onLongPress(date),
          child: Padding(
            padding: const EdgeInsets.all(4),
            // Shrinks rather than overflows if text is larger than the cell.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: t.labelMedium?.copyWith(
                      color: isFuture ? c.border : (selected ? fg : c.muted),
                    ),
                  ),
                  Text(
                    main.isEmpty ? ' ' : main,
                    style: t.titleMedium?.copyWith(
                      color: e?.status == DayStatus.skipped && !selected
                          ? c.skipped
                          : fg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _mainText(DayEntry e) =>
      e.status == DayStatus.got ? formatQty(e.totalMl) : '—';

  String _semanticLabel(DayEntry? e) {
    final day = '${date.day}';
    return switch (e?.status) {
      DayStatus.got => '$day, ${formatLitres(e!.totalMl)}',
      DayStatus.skipped => '$day, no milk',
      null => '$day, not logged',
    };
  }
}
