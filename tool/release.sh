#!/usr/bin/env bash
# Builds the release APKs and publishes them as a GitHub Release, which the
# app's update banner picks up. Version comes from pubspec.yaml.
#
#   tool/release.sh notes.md     # notes.md = what's new, shown on GitHub
#
# Bump `version:` in pubspec.yaml first (e.g. 1.0.1+4); the build number
# must always increase or Android refuses to install the update.
set -euo pipefail
cd "$(dirname "$0")/.."
NOTES=${1:?usage: tool/release.sh notes.md}
V=$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)
git diff --quiet || { echo "Commit your changes first."; exit 1; }
grep -q "'$V':" lib/changelog.dart || {
  echo "Add a '$V' entry to lib/changelog.dart (shown as \"What's new\")."; exit 1; }

flutter test
flutter build apk --release --split-per-abi

mkdir -p build/release && rm -f build/release/*.apk
# x86_64 is only for PC emulators; real phones are arm64 (most) or arm.
# Names carry no version, so .../releases/latest/download/<name> is a
# stable link to the newest APK (lib/links.dart shares it).
for abi in arm64-v8a armeabi-v7a; do
  cp "build/app/outputs/flutter-apk/app-$abi-release.apk" \
     "build/release/milk-tracker-$abi.apk"
done

gh release create "v$V" build/release/*.apk \
  --title "Milk Tracker $V" --notes-file "$NOTES"
echo "Published v$V — phones will show the update banner on next open."
