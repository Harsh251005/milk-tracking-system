import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../state/update_controller.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/section_card.dart';

/// Shown on Today when a newer version is published. Walks the person
/// through Android's install screens, which are the confusing part.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  static const _steps = [
    'Tap Update below and wait for the download.',
    'If asked which app to use, pick "Package installer".',
    'First time only: if asked, turn on "Allow from this source", then come '
        'back here and tap Update again.',
    'Tap Update on the screen that opens. Your milk log stays as it is.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableUpdateProvider).value;
    if (release == null) return const SizedBox.shrink();
    final state = ref.watch(updateControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    void start() => ref.read(updateControllerProvider.notifier).start(release);

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
            const SizedBox(height: 12),
            for (final (i, step) in _steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.primary,
                      child: Text(
                        '${i + 1}',
                        style: t.labelMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step, style: t.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
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
                    _Note(text: message, color: scheme.errorContainer),
                  if (state is UpdateInstallerOpened)
                    _Note(
                      text:
                          "Didn't finish? That's fine — tap Update again. "
                          "It won't download again.",
                      color: context.colors.missingSoft,
                    ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: start,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(switch (state) {
                      UpdateFailed() => 'Try again',
                      UpdateInstallerOpened() => 'Update again',
                      _ => 'Update',
                    }),
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

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
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
