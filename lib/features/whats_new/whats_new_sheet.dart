import 'package:flutter/material.dart';

import '../../ui/theme.dart';

/// "What's new" after an update: a short, friendly list of changes.
Future<void> showWhatsNew(
  BuildContext context,
  List<(String version, List<String> notes)> versions,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _WhatsNewSheet(versions: versions),
);

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet({required this.versions});

  final List<(String, List<String>)> versions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? 1 : 0.4, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What's new",
            textAlign: TextAlign.center,
            style: t.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Milk Tracker has been updated.',
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: context.colors.muted),
          ),
          for (final (version, notes) in versions) ...[
            const SizedBox(height: 20),
            if (versions.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Version $version', style: t.titleMedium),
              ),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: context.colors.got,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(note, style: t.bodyLarge)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
