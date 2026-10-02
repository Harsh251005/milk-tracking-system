/// Where the app is published. One place, so a repo move is a one-line fix.
library;

const repoPath = 'Harsh251005/milk-tracking-system';

/// Always the newest APK for modern phones (release assets have stable,
/// version-free names; see tool/release.sh).
const downloadLink =
    'https://github.com/$repoPath/releases/latest/download/milk-tracker-arm64-v8a.apk';

/// The release page, which also has the build for very old phones.
const releasesPage = 'https://github.com/$repoPath/releases/latest';

const latestReleaseApi =
    'https://api.github.com/repos/$repoPath/releases/latest';

const shareAppText =
    'Milk Tracker: log daily milk in one tap, see the monthly bill, and '
    'message the milkman on WhatsApp. Free, for Android.\n\n'
    'Download: $downloadLink\n'
    '(Very old phone? Pick the other file here: $releasesPage)';
