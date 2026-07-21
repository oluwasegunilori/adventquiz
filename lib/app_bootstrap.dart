import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'data/firestore_room_repository.dart';
import 'data/local_room_repository.dart';
import 'data/room_repository.dart';
import 'firebase_options.dart';

class AppBootstrap {
  AppBootstrap({
    required this.repository,
    required this.usingFirebase,
  });

  final RoomRepository repository;
  final bool usingFirebase;

  static Future<AppBootstrap> init() async {
    if (DefaultFirebaseOptions.isConfigured) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        return AppBootstrap(
          repository: FirestoreRoomRepository(),
          usingFirebase: true,
        );
      } catch (e, st) {
        debugPrint('Firebase init failed, falling back to local: $e\n$st');
      }
    }
    return AppBootstrap(
      repository: LocalRoomRepository(),
      usingFirebase: false,
    );
  }
}
