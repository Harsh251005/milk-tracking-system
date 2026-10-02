import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/release.dart';
import '../../state/providers.dart';
import '../../ui/widgets/section_card.dart';

/// Opens the APK link; Android downloads it, and tapping the download
/// installs the update over the current app, keeping all data.
Future<void> downloadUpdate(BuildContext context, AppRelease release) async {
  final ok = await launchUrl(
    Uri.parse(release.apkUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: const Text("Couldn't open the download. Try again later."),
      ),
    );
  }
}

/// Shown on Today when a newer version is published.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableUpdateProvider).value;
    if (release == null) return const SizedBox.shrink();
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
              'Tap below, then tap the downloaded file to install. Your milk '
              'log stays as it is.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: () => downloadUpdate(context, release),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download update'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Milk Tracker 1.0.0" at the bottom of Settings, with the update if any.
class VersionFooter extends ConsumerWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(installedVersionProvider).value;
    final release = ref.watch(availableUpdateProvider).value;
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
              onPressed: () => downloadUpdate(context, release),
              child: Text('Update to ${release.version}'),
            )
          else if (version != null)
            Text('Up to date', style: t.bodySmall),
        ],
      ),
    );
  }
}
