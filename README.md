# Milk Tracker

A dead-simple Android app for a family to log daily milk deliveries, see the
monthly bill, and share exactly what they choose with the milkman on WhatsApp.
Two phones in one household stay in sync.

**Constraints:** zero running cost (Firebase Spark free plan), APK-only
distribution via GitHub Releases — no Play Store.

## Status
v1.0.1 — adds a first-launch intro, "Share Milk Tracker" and a one-tap
download link. v1.0.0 — ready for the family. Daily logging, monthly bill, family sync,
WhatsApp messages to the milkman, going away, reminders, Google backup and
in-app updates.

## Installing on a family phone
1. On the phone, open this link — it always downloads the newest version:
   https://github.com/Harsh251005/milk-tracking-system/releases/latest/download/milk-tracker-arm64-v8a.apk
   (Very old phones: pick `milk-tracker-armeabi-v7a.apk` on
   https://github.com/Harsh251005/milk-tracking-system/releases/latest)
2. Or share it from a phone that has the app: Settings → **Share Milk
   Tracker** sends the link on WhatsApp.
3. Tap the download. Android asks to allow installing from the browser once —
   allow it, then tap **Install**.
4. Open **Milk Tracker**:
   - **First person in the house:** enter your name, the milk and its price,
     and the milkman's number.
   - **Everyone else:** tap **Join their tracker** and scan the code shown on
     the first phone under Settings → Family → Add a family member.
5. Tap **Back up** on the card on Today so the log can be restored on a new
   phone (welcome screen → **Restore with Google**).

Updates: when a new version is published, Today shows **Update available**;
tap it, then tap the download to install over the old version. Data stays. Phones in one household see and log the same days live.
Each phone signs in anonymously (no login screen); logging works offline and
syncs within seconds of reconnecting.

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
- **Family:** Settings → Family → *Add a family member* shows a QR code and
  a 6-digit code (valid 24 h). On the other phone, *Join their tracker* scans
  or types it. Old or lost phones can be removed from the family.
- **Message the milkman:** monthly bill, today's delivery, or tomorrow's
  order. Switches choose what goes in (day list, litres, price, amount), the
  text can be edited, and *Open WhatsApp* opens his chat with it filled in —
  nothing is ever sent automatically. Switch choices are remembered per phone.
- **Going away:** pick From/Until; those days are marked no milk in one go,
  with a ready "please don't send milk until …" message for the milkman.
- **Daily reminder:** Settings → Reminder sends "Did milk come today?" at a
  chosen time, skipped on days already logged (on any phone).
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

## Icons
Artwork is drawn in code by `tool/make_icons.py` (Pillow) into `assets/icon/`,
then turned into Android resources:
```bash
python tool/make_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Firebase
Project `milk-tracker-hd` (free Spark plan, Firestore in `asia-south1`).
```
users/{uid}                         -> {householdId}
joinCodes/{6 digits}                -> householdId, invitedBy, expiresAt
households/{id}                     -> members, products, milkman
households/{id}/entries/{yyyy-MM-dd}
households/{id}/payments/{yyyy-MM}
```
Access rules live in `firestore.rules`: only a household's members can read
or write it, and a phone can add only itself, only with a live code.
Test them against the local emulator, then deploy:
```bash
cd tool/rules-test && npm install && npm test   # free, runs locally
./tool/deploy_rules.sh                          # uses your gcloud login
```

## Releasing an update
1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+4` — the number after `+`
   must always go up).
2. Write what changed in a notes file, commit everything, then:
   `tool/release.sh notes.md` — runs the tests, builds one APK per phone type
   and publishes a GitHub Release. Phones show the update banner next open.

Release APKs are signed with a local keystore that is never committed
(`android/key.properties`, `*.jks` are gitignored). **Back the keystore up** —
losing it means every phone must uninstall (and restore from Google) to
update. Its SHA-1 is registered with Firebase for Google sign-in.

Release builds strip resources only referenced by name; anything like that
must be listed in `android/app/src/main/res/raw/keep.xml`.

`tool/wipe_data.py` deletes all Firebase data (dry run unless `--yes`).
