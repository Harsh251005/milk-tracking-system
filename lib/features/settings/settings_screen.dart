import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/format.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';

/// Read-only for M1; editing arrives with first-run setup in M2.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(milkRepositoryProvider).currentUid;
    return AsyncView(
      value: ref.watch(householdProvider),
      builder: (h) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SectionLabel('Milk'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, p) in h.products.indexed) ...[
                  if (i > 0) const _Divider(),
                  _Row(
                    icon: Icons.water_drop_rounded,
                    title: p.name,
                    subtitle:
                        '${formatRupees(p.ratePaise)} per litre · usually ${formatLitres(p.usualMl)}',
                  ),
                ],
              ],
            ),
          ),
          const SectionLabel('Milkman'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: _Row(
              icon: Icons.person_rounded,
              title: h.milkmanName ?? 'Not set',
              subtitle: h.milkmanPhone == null
                  ? 'Add a WhatsApp number'
                  : '+${h.milkmanPhone}',
            ),
          ),
          const SectionLabel('Family'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, m) in h.members.entries.indexed) ...[
                  if (i > 0) const _Divider(),
                  _Row(
                    icon: Icons.phone_android_rounded,
                    title: m.value,
                    subtitle: m.key == currentUid ? 'This phone' : 'Connected',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                Text(
                  subtitle,
                  style: t.bodyMedium?.copyWith(color: context.colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 76, color: context.colors.border);
}
