# Milk Tracker

A dead-simple Android app for a family to log daily milk deliveries, see the
monthly bill, and share exactly what they choose with the milkman on WhatsApp.
Two phones in one household stay in sync.

**Constraints:** zero running cost (Firebase Spark free plan), APK-only
distribution via GitHub Releases — no Play Store.

## Status
M1 — real screens (Today, Month, Settings) running on in-memory sample data.
Nothing is saved yet; Firestore arrives in M3.

## What it does today
- **Today:** usual quantity prefilled; one tap logs "Got 1 L" or "No milk today".
  Shows who logged it and the month so far.
- **Month:** calendar with litres per day, "no milk" and "not logged" days;
  tap a day to edit, press-and-hold to select several and edit them together;
  monthly total, bill, and mark as paid.
- **Price per log:** each milk type has a saved price. Any log (today, a past
  day, or several days at once) can use a different price via "Change". If it
  differs from the saved one, the app explains and asks: only for these days,
  use it from now on, or keep the saved price. Logged days keep their own price.
- **Settings:** milk type and rate, milkman, family members (read-only for now).

## Layout
```
lib/domain/    pure Dart: models, billing, formatting, entry builders (unit-tested)
lib/data/      MilkRepository interface + in-memory implementation
lib/state/     Riverpod providers — the one place the backend is chosen
lib/ui/        theme tokens and shared widgets
lib/features/  today/, month/, settings/
```
Screens only talk to `MilkRepository`, so the backend can be swapped without
touching UI code. Money is stored in paise and quantity in millilitres (ints).

## Develop
```bash
flutter pub get
flutter run            # Android device over USB
flutter test
```
Font: Nunito (SIL Open Font License, `assets/fonts/OFL.txt`), bundled in two
subsets — `latin` for ½ ¼ ¾ and `latin-ext` for ₹ — with the second set as a
fallback in the theme.

## Release (later milestones)
`flutter build apk --release`, signed with a local keystore that is never
committed (`android/key.properties`, `*.jks` are gitignored). Back the keystore
up — losing it forces every phone to uninstall before updating.
