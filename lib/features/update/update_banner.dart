import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../state/update_controller.dart';
import '../../ui/widgets/section_card.dart';

/// Shown on Today when a newer version is published. Downloads inside the
/// app (no browser) with progress, then opens Android's installer.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableUpdateProvider).value;
    if (release == null) return const SizedBox.shrink();
    final state = ref.watch(updateControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        color: scheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Update available · version ${release.version}',
                    style: t.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap Update, then Install on the screen that opens. Your milk '
              'log stays as it is.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            switch (state) {
              UpdateDownloading(:final progress) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading… ${(progress * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: t.titleMedium,
                  ),
                ],
              ),
              _ => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state case UpdateFailed(:final message))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message, style: t.bodyLarge),
                      ),
                    ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => ref
                        .read(updateControllerProvider.notifier)
                        .start(release),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(state is UpdateFailed ? 'Try again' : 'Update'),
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// "Milk Tracker 1.0.1" at the bottom of Settings, with the update if any.
class VersionFooter extends ConsumerWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(installedVersionProvider).value;
    final release = ref.watch(availableUpdateProvider).value;
    final downloading =
        ref.watch(updateControllerProvider) is UpdateDownloading;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          Text(
            version == null ? 'Milk Tracker' : 'Milk Tracker $version',
            style: t.bodySmall,
          ),
          if (release != null)
            TextButton(
              onPressed: downloading
                  ? null
                  : () => ref
                        .read(updateControllerProvider.notifier)
                        .start(release),
              child: Text(
                downloading
                    ? 'Downloading update…'
                    : 'Update to ${release.version}',
              ),
            )
          else if (version != null)
            Text('Up to date', style: t.bodySmall),
        ],
      ),
    );
  }
}
