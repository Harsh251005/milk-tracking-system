# Milk Tracker

A dead-simple Android app for a family to log daily milk deliveries, see the
monthly bill, and share exactly what they choose with the milkman on WhatsApp.
Two phones in one household stay in sync.

**Constraints:** zero running cost (Firebase Spark free plan), APK-only
distribution via GitHub Releases — no Play Store.

## Status
M0 — project skeleton. See milestones in the plan.

## Develop
```bash
flutter pub get
flutter run            # Android device over USB
flutter test
```

## Release (later milestones)
`flutter build apk --release`, signed with a local keystore that is never
committed (`android/key.properties`, `*.jks` are gitignored). Back the keystore
up — losing it forces every phone to uninstall before updating.
