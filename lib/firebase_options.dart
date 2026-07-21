// Generated-style options placeholder.
// Run `flutterfire configure` (or paste your Firebase web config) to enable
// online multiplayer across devices. Until then the app uses local mode.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured {
    final opts = currentPlatform;
    return opts.apiKey != 'YOUR_API_KEY' &&
        opts.projectId != 'YOUR_PROJECT_ID' &&
        opts.appId != 'YOUR_APP_ID';
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1KjeM26ij00OKFB_mZb9TTNlfZIKG9YU',
    appId: '1:679500370598:web:db57482b943156edebda67',
    messagingSenderId: '679500370598',
    projectId: 'churchgamey',
    authDomain: 'churchgamey.firebaseapp.com',
    storageBucket: 'churchgamey.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDM11fg62HkdTFHsElXkgdSvGq18UM3Jbo',
    appId: '1:679500370598:android:19535f4bc195afc6ebda67',
    messagingSenderId: '679500370598',
    projectId: 'churchgamey',
    storageBucket: 'churchgamey.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBadZTDkCNLSTM3dQErqyy9Yne5-pFdcTk',
    appId: '1:679500370598:ios:fa1736f35221e93aebda67',
    messagingSenderId: '679500370598',
    projectId: 'churchgamey',
    storageBucket: 'churchgamey.firebasestorage.app',
    iosBundleId: 'com.adventquiz.adventquiz',
  );
}
