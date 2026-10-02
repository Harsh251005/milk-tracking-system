import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/format.dart';
import '../../domain/models.dart';
import '../theme.dart';
import 'price_input_dialog.dart';

const qtyStepMl = 250;
const _quickPicksMl = [500, 1000, 1500, 2000];

/// One row per product: − [1½ L] + , quick-pick chips, and the price line.
/// Used by Today, the day editor sheet and bulk edit.
class QuantityEditor extends StatelessWidget {
  const QuantityEditor({
    super.key,
    required this.products,
    required this.quantitiesMl,
    required this.onChanged,
    required this.ratesPaise,
    required this.onRatesChanged,
  });

  final List<Product> products;
  final Map<String, int> quantitiesMl;
  final ValueChanged<Map<String, int>> onChanged;

  /// Price per litre for this log; may differ from the product's saved rate.
  final Map<String, int> ratesPaise;
  final ValueChanged<Map<String, int>> onRatesChanged;

  void _set(String productId, int ml) {
    HapticFeedback.selectionClick();
    onChanged({...quantitiesMl, productId: ml.clamp(0, 20000)});
  }

  @override
  Widget build(BuildContext context) {
    final showNames = products.length > 1;
    return Column(
      children: [
        for (final (i, p) in products.indexed) ...[
          if (i > 0) const SizedBox(height: 20),
          if (showNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          _Stepper(
            ml: quantitiesMl[p.id] ?? 0,
            onChanged: (ml) => _set(p.id, ml),
          ),
          const SizedBox(height: 12),
          _QuickPicks(
            selectedMl: quantitiesMl[p.id] ?? 0,
            onPick: (ml) => _set(p.id, ml),
          ),
          const SizedBox(height: 8),
          _PriceLine(
            product: p,
            ratePaise: ratesPaise[p.id] ?? p.ratePaise,
            onChanged: (paise) => onRatesChanged({...ratesPaise, p.id: paise}),
          ),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.ml, required this.onChanged});

  final int ml;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.remove,
          label: 'Less',
          onTap: ml > 0 ? () => onChanged(ml - qtyStepMl) : null,
        ),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: formatQty(ml)),
                  TextSpan(
                    text: ' L',
                    style: TextStyle(fontSize: 26, color: context.colors.muted),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontSize: 44),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add,
          label: 'More',
          onTap: () => onChanged(ml + qtyStepMl),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: onTap == null
            ? context.colors.skippedSoft
            : scheme.primaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Icon(
              icon,
              size: 30,
              color: onTap == null ? context.colors.muted : scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickPicks extends StatelessWidget {
  const _QuickPicks({required this.selectedMl, required this.onPick});

  final int selectedMl;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (i, ml) in _quickPicksMl.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: ml == selectedMl ? scheme.primary : context.colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: ml == selectedMl
                      ? scheme.primary
                      : context.colors.border,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPick(ml),
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
                      formatQty(ml),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: ml == selectedMl
                            ? scheme.onPrimary
                            : scheme.onSurface,
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

/// "₹70 per litre · Change". Turns amber when this log's price differs
/// from the saved one, with a one-tap way back.
class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.product,
    required this.ratePaise,
    required this.onChanged,
  });

  final Product product;
  final int ratePaise;
  final ValueChanged<int> onChanged;

  Future<void> _edit(BuildContext context) async {
    final paise = await showPriceInputDialog(
      context,
      productName: product.name,
      currentPaise: ratePaise,
    );
    if (paise != null) onChanged(paise);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final differs = ratePaise != product.ratePaise;
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: differs ? context.colors.missingSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${formatRupees(ratePaise)} per litre',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (differs)
                    TextSpan(
                      text: '  (usually ${formatRupees(product.ratePaise)})',
                      style: TextStyle(color: context.colors.muted),
                    ),
                ],
              ),
              style: t.bodyMedium,
            ),
          ),
          if (differs)
            TextButton(
              onPressed: () => onChanged(product.ratePaise),
              child: const Text('Reset'),
            ),
          TextButton(
            onPressed: () => _edit(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
