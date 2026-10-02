import 'domain/release.dart';

/// What changed in each version, in plain words, shown once after updating
/// ("What's new"). Add an entry for every release — tool/release.sh checks.
const changelog = <String, List<String>>{
  '1.0.4': [
    'Share Milk Tracker now sends the app itself. The other person just taps '
        'the file in WhatsApp to install it.',
    'Clear steps on the update card, so updating is easy.',
    'This note, after every update, showing what changed.',
  ],
};

/// Versions whose notes to show: those newer than [lastSeen], up to and
/// including [current], newest first. Nothing on a fresh install.
List<(String version, List<String> notes)> whatsNewFor({
  required String current,
  required String? lastSeen,
  required bool isUpgrade,
}) {
  if (!isUpgrade) return const [];
  final versions =
      changelog.keys
          .where(
            (v) =>
                compareVersions(v, current) <= 0 &&
                (lastSeen == null
                    ? compareVersions(v, current) == 0
                    : compareVersions(v, lastSeen) > 0),
          )
          .toList()
        ..sort((a, b) => compareVersions(b, a));
  return [for (final v in versions) (v, changelog[v]!)];
}
