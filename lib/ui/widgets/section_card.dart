import 'package:flutter/material.dart';

import '../theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color == null ? context.colors.border : Colors.transparent,
        ),
      ),
      child: child,
    );
  }
}

/// Big value over a small label, e.g. "28 L" / "Milk".
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: t.headlineSmall?.copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase heading above a group of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: context.colors.muted, letterSpacing: 1.1),
      ),
    );
  }
}
