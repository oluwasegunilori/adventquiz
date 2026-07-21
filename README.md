# AdventQuiz

Kahoot-style live Bible trivia for Seventh-day Adventist groups — Flutter web first.

## Run (local demo)

```bash
flutter pub get
flutter run -d chrome
```

Without Firebase configured, the app uses **local demo mode** (SharedPreferences / localStorage). Host in one browser tab, join from another tab on the same device with the PIN.

Tracked Firebase config uses `YOUR_*` placeholders so the repo stays free of real keys. The app falls back to local mode until you configure Firebase locally.

## Enable online multiplayer (Firebase)

**Do not commit real API keys, `google-services.json`, or `GoogleService-Info.plist`.** Configure them only on your machine (or CI secrets).

### 0. Rotate credentials (required if keys were revoked)

GitHub secret scanning revoked previously committed Firebase client keys. They remain in **git history**, so treat them as compromised forever.

1. Open [Firebase Console](https://console.firebase.google.com/) → your project (or create a new one).
2. **Project settings → General → Your apps** — for each Web / Android / iOS app that had leaked keys, either:
   - **Restrict / rotate** the Browser / Android / iOS API key in [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials), or
   - Delete the old app registrations and **Add app** again (Web, Android `com.adventquiz.adventquiz`, iOS `com.adventquiz.adventquiz`) to get fresh app IDs and keys.
3. Confirm revoked keys are no longer usable (create room / Auth should fail with old config — expected).

Optional history purge (does **not** replace revoke): use [`git filter-repo`](https://github.com/newren/git-filter-repo) or BFG to remove secret files from history, then coordinate a force-push with collaborators. Prefer scrubbing the current tree (already done) + revoke over rewriting `master` unless the team agrees.

### 1. Generate local Firebase config

```bash
# Install once: dart pub global activate flutterfire_cli
flutterfire configure
```

This regenerates (locally, untracked):

- `lib/firebase_options.dart` — replace placeholders with real options
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- FlutterFire metadata under `firebase.json`

Or copy the `.example` templates and paste values from the Firebase console:

```bash
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
# then edit lib/firebase_options.dart with web/android/ios options
```

Keep `lib/firebase_options.dart` placeholders in git; after `flutterfire configure`, leave the real file uncommitted (or restore placeholders before pushing).

### 2. Enable Anonymous Auth (required for Create / Join room)

In Firebase Console → your project:

1. Open **Build → Authentication**
2. Click **Get started** if needed
3. **Sign-in method → Anonymous → Enable → Save**
4. **Authentication → Settings → Authorized domains** — add your hosting domain (e.g. `YOUR_PROJECT_ID.web.app`)

### 3. Enable Cloud Firestore

**Build → Firestore Database → Create database** (production mode; deploy rules next).

### 4. Deploy rules & hosting

```bash
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
flutter build web
firebase deploy --only hosting
```

The home footer should say **Online rooms ready** once Auth + Firestore + valid local config are in place.

## Game loop

1. **Host** picks a pack → gets a 6-digit PIN.
2. **Players** join with PIN + nickname.
3. Host starts → questions sync → answers lock → reveal → leaderboard → podium.

## Packs

Starter packs live in `assets/packs/`:

- Bible Basics
- Gospels & Jesus
- Adventist Distinctives
