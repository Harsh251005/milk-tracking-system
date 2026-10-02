import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/share_prefs.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/share_text.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/quantity_editor.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';
import 'send.dart';

enum MessageKind { bill, today, tomorrow }

/// Builds a message for the milkman. The person chooses what goes in,
/// can edit the text, and sends it themselves from WhatsApp.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, required this.kind, this.month});

  final MessageKind kind;

  /// Month for the bill; defaults to the current one.
  final YearMonth? month;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _prefs = SharePrefs();
  late MessageKind _kind = widget.kind;
  late YearMonth _month = widget.month ?? monthOf(ref.read(todayProvider));
  BillOptions _bill = const BillOptions();
  bool _todayPrice = false;
  Map<String, int>? _tomorrow;

  final _text = TextEditingController();
  String _lastGenerated = '';

  @override
  void initState() {
    super.initState();
    _prefs.loadBill().then((o) => mounted ? setState(() => _bill = o) : null);
    _prefs.loadTodayPrice().then(
      (v) => mounted ? setState(() => _todayPrice = v) : null,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setBill(BillOptions o) {
    setState(() => _bill = o);
    _prefs.saveBill(o);
  }

  /// Puts freshly generated text in the box. Runs after the frame, because
  /// changing a controller during build isn't allowed.
  void _sync(String generated) {
    if (generated == _lastGenerated) return;
    _lastGenerated = generated;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _text.text = generated;
    });
  }

  Future<void> _send(Household h) async {
    final ok = await sendToMilkman(phone: h.milkmanPhone, text: _text.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text("Couldn't open WhatsApp. Is it installed?"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final month = _kind == MessageKind.bill ? _month : monthOf(today);
    return Scaffold(
      appBar: AppBar(title: const Text('Message milkman')),
      body: AsyncView(
        value: ref.watch(householdProvider),
        builder: (h) => AsyncView(
          value: ref.watch(monthEntriesProvider(month)),
          builder: (entries) => _body(context, h, entries, today),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    Household h,
    List<DayEntry> entries,
    DateTime today,
  ) {
    final t = Theme.of(context).textTheme;
    final todayEntry = entries
        .where((e) => isSameDay(e.date, today))
        .firstOrNull;
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowQty = _tomorrow ??= {
      for (final p in h.products) p.id: p.usualMl,
    };

    final generated = switch (_kind) {
      MessageKind.bill => billMessage(
        household: h,
        month: _month,
        entries: entries,
        today: today,
        options: _bill,
      ),
      MessageKind.today when todayEntry != null => todayMessage(
        household: h,
        entry: todayEntry,
        includePrice: _todayPrice,
      ),
      MessageKind.today => '',
      MessageKind.tomorrow => tomorrowMessage(
        household: h,
        tomorrow: tomorrow,
        quantitiesMl: tomorrowQty,
      ),
    };
    _sync(generated);
    final canSend = generated.isNotEmpty;
    final milkman = (h.milkmanName?.isNotEmpty ?? false)
        ? h.milkmanName!
        : 'the milkman';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _KindSelector(
                selected: _kind,
                onChanged: (k) => setState(() => _kind = k),
              ),
              const SizedBox(height: 16),
              switch (_kind) {
                MessageKind.bill => _BillOptionsCard(
                  month: _month,
                  canGoForward: _month != monthOf(today),
                  onMonth: (d) => setState(() => _month = addMonths(_month, d)),
                  options: _bill,
                  onChanged: _setBill,
                ),
                MessageKind.today => SectionCard(
                  child: todayEntry == null
                      ? Text(
                          "Today isn't logged yet. Log it on the Today "
                          'screen first.',
                          style: t.bodyLarge,
                        )
                      : _Toggle(
                          label: 'Price per litre',
                          value: _todayPrice,
                          onChanged: (v) {
                            setState(() => _todayPrice = v);
                            _prefs.saveTodayPrice(v);
                          },
                        ),
                ),
                MessageKind.tomorrow => SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'How much for tomorrow?',
                        style: t.titleMedium?.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final p in h.products) ...[
                        if (h.products.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(p.name, style: t.titleMedium),
                          ),
                        QuantityPicker(
                          ml: tomorrowQty[p.id] ?? 0,
                          onChanged: (ml) => setState(
                            () => _tomorrow = {...tomorrowQty, p.id: ml},
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () =>
                              _tomorrow = {for (final p in h.products) p.id: 0},
                        ),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('No milk tomorrow'),
                      ),
                    ],
                  ),
                ),
              },
              const SectionLabel('Message'),
              TextField(
                controller: _text,
                minLines: 4,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: t.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You can edit the message. Changing the options above '
                'rewrites it.',
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.card,
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.got,
                  ),
                  onPressed: canSend ? () => _send(h) : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    h.milkmanPhone == null ? 'Share message' : 'Open WhatsApp',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  h.milkmanPhone == null
                      ? "Add $milkman's number in Settings to open his "
                            'chat directly.'
                      : 'Opens a chat with $milkman. You press send there.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: context.colors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Three equal buttons in one row: Monthly bill · Today · Tomorrow.
class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onChanged});

  final MessageKind selected;
  final ValueChanged<MessageKind> onChanged;

  static const _labels = {
    MessageKind.bill: 'Monthly bill',
    MessageKind.today: 'Today',
    MessageKind.tomorrow: 'Tomorrow',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (i, kind) in MessageKind.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: kind == selected ? scheme.primary : context.colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: kind == selected
                      ? scheme.primary
                      : context.colors.border,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(kind),
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _labels[kind]!,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: kind == selected
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BillOptionsCard extends StatelessWidget {
  const _BillOptionsCard({
    required this.month,
    required this.canGoForward,
    required this.onMonth,
    required this.options,
    required this.onChanged,
  });

  final YearMonth month;
  final bool canGoForward;
  final ValueChanged<int> onMonth;
  final BillOptions options;
  final ValueChanged<BillOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => onMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy')
                      .format(DateTime(month.year, month.month)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: canGoForward ? () => onMonth(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          _Toggle(
            label: 'Day-by-day list',
            value: options.dayList,
            onChanged: (v) => onChanged(options.copyWith(dayList: v)),
          ),
          _Toggle(
            label: 'Total litres',
            value: options.totalLitres,
            onChanged: (v) => onChanged(options.copyWith(totalLitres: v)),
          ),
          _Toggle(
            label: 'Price per litre',
            value: options.rate,
            onChanged: (v) => onChanged(options.copyWith(rate: v)),
          ),
          _Toggle(
            label: 'Total amount',
            value: options.amount,
            onChanged: (v) => onChanged(options.copyWith(amount: v)),
          ),
          if (!options.dayList)
            _Toggle(
              label: 'No-milk days',
              value: options.noMilkDays,
              onChanged: (v) => onChanged(options.copyWith(noMilkDays: v)),
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    title: Text(label, style: Theme.of(context).textTheme.titleMedium),
    value: value,
    onChanged: onChanged,
  );
}
