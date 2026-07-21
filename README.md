# AdventQuiz

Kahoot-style live Bible trivia for Seventh-day Adventist groups — Flutter web first.

## Run (local demo)

```bash
flutter pub get
flutter run -d chrome
```

Without Firebase configured, the app uses **local demo mode** (SharedPreferences / localStorage). Host in one browser tab, join from another tab on the same device with the PIN.

## Enable online multiplayer (Firebase)

Hosting alone is not enough — **Authentication** and **Firestore** must be enabled.

### 1. Enable Anonymous Auth (required for Create / Join room)

In [Firebase Console](https://console.firebase.google.com/project/churchgamey/authentication) → project **churchgamey**:

1. Open **Build → Authentication**
2. Click **Get started** if you have not already
3. **Sign-in method** → **Anonymous** → **Enable** → Save

Also under **Authentication → Settings → Authorized domains**, confirm your hosting domain is listed (e.g. `churchgamey.web.app`, `churchgamey.firebaseapp.com`).

### 2. Enable Cloud Firestore

**Build → Firestore Database → Create database** (start in production mode; rules are deployed separately).

### 3. Deploy rules

```bash
firebase use churchgamey
firebase deploy --only firestore:rules
```

### 4. Rebuild & redeploy web (after Auth is enabled)

```bash
flutter build web
firebase deploy --only hosting
```

The home footer should say **Online rooms ready**. Create room should work after Anonymous Auth is on.

## Game loop

1. **Host** picks a pack → gets a 6-digit PIN.
2. **Players** join with PIN + nickname.
3. Host starts → questions sync → answers lock → reveal → leaderboard → podium.

## Packs

Starter packs live in `assets/packs/`:

- Bible Basics
- Gospels & Jesus
- Adventist Distinctives
