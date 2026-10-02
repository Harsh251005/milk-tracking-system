# Milk Tracker

A dead-simple Android app for a family to log daily milk deliveries, see the
monthly bill, and share exactly what they choose with the milkman on WhatsApp.
Two phones in one household stay in sync.

**Constraints:** zero running cost (Firebase Spark free plan), APK-only
distribution via GitHub Releases — no Play Store.

## Status
M3 — daily logging verified offline. Each phone signs in anonymously (no
login screen). Logs made in airplane mode survive an app restart and sync to
the server within seconds of reconnecting. Pairing a second phone into the
same household arrives in M5.

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
- **First run:** three short steps — your name, your milk (type, price,
  usual quantity), and the milkman's WhatsApp number (skippable).
- **Settings:** edit milk type, price and usual quantity; add or remove milk
  types; edit the milkman; change your display name.
- **Always today:** the date refreshes at midnight and when the app returns
  from the background, so an app left open overnight never logs to yesterday.
- **Errors are loud:** a save the server rejects shows a red banner with the
  reason; it never fails silently.

## Layout
```
lib/domain/    pure Dart: models, billing, formatting, entry builders (unit-tested)
lib/data/      MilkRepository / AccountRepository interfaces, Firestore
               implementation (firebase/), in-memory version for tests
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

## Firebase
Project `milk-tracker-hd` (free Spark plan, Firestore in `asia-south1`).
```
users/{uid}                         -> {householdId}
households/{id}                     -> members, products, milkman
households/{id}/entries/{yyyy-MM-dd}
households/{id}/payments/{yyyy-MM}
```
Access rules live in `firestore.rules`: only a household's members can read
or write it. Deploy with `tool/deploy_rules.sh` (uses your gcloud login).

## Release (later milestones)
`flutter build apk --release`, signed with a local keystore that is never
committed (`android/key.properties`, `*.jks` are gitignored). Back the keystore
up — losing it forces every phone to uninstall before updating.
