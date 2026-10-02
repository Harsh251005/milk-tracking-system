/// A published version of the app (a GitHub Release with an APK attached).
class AppRelease {
  const AppRelease({
    required this.version,
    required this.apkUrl,
    this.notes = '',
  });

  /// "1.0.1" (no leading v).
  final String version;
  final String apkUrl;
  final String notes;
}

List<int> _parts(String v) => v
    .trim()
    .replaceFirst(RegExp(r'^[vV]'), '')
    .split('+')
    .first
    .split('.')
    .map((p) => int.tryParse(p) ?? 0)
    .toList();

/// Negative if [a] is older than [b], zero if equal, positive if newer.
/// Compares numerically, so 1.0.10 is newer than 1.0.9.
int compareVersions(String a, String b) {
  final x = _parts(a);
  final y = _parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// Reads GitHub's "latest release" JSON. Releases carry one APK per phone
/// type (e.g. `milk-tracker-v1.0.1-arm64-v8a.apk`); picks the one for
/// [abi], else any APK. Null if it has no APK attached.
AppRelease? releaseFromGitHub(Map<String, dynamic> json, {String? abi}) {
  final tag = json['tag_name'] as String?;
  final apks = (json['assets'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .where((a) => (a['name'] as String? ?? '').endsWith('.apk'))
      .toList();
  final apk =
      apks
          .where((a) => abi != null && (a['name'] as String).contains(abi))
          .firstOrNull ??
      apks.firstOrNull;
  if (tag == null || apk == null) return null;
  return AppRelease(
    version: tag.replaceFirst(RegExp(r'^[vV]'), ''),
    apkUrl: apk['browser_download_url'] as String,
    notes: json['body'] as String? ?? '',
  );
}

/// The release to offer, or null if [installed] is already up to date.
AppRelease? updateFor(String installed, AppRelease? latest) =>
    latest != null && compareVersions(latest.version, installed) > 0
    ? latest
    : null;
