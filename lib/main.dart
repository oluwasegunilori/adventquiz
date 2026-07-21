import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_bootstrap.dart';
import 'app_router.dart';
import 'data/local_room_repository.dart';
import 'data/room_repository.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppBootstrap bootstrap;
  try {
    bootstrap = await AppBootstrap.init().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('Firebase init timed out; using local mode');
        return AppBootstrap(
          repository: LocalRoomRepository(),
          usingFirebase: false,
        );
      },
    );
  } catch (e, st) {
    debugPrint('Bootstrap failed: $e\n$st');
    bootstrap = AppBootstrap(
      repository: LocalRoomRepository(),
      usingFirebase: false,
    );
  }

  final sounds = SoundService();
  // Don't block first frame on audio prefs.
  unawaited(
    sounds.init().catchError((Object e, StackTrace st) {
      debugPrint('Sound init error: $e\n$st');
    }),
  );

  runApp(AdventQuizApp(bootstrap: bootstrap, sounds: sounds));
}

class AdventQuizApp extends StatelessWidget {
  const AdventQuizApp({
    super.key,
    required this.bootstrap,
    required this.sounds,
  });

  final AppBootstrap bootstrap;
  final SoundService sounds;

  @override
  Widget build(BuildContext context) {
    final router = createRouter(usingFirebase: bootstrap.usingFirebase);
    return MultiProvider(
      providers: [
        Provider<RoomRepository>.value(value: bootstrap.repository),
        ChangeNotifierProvider<SoundService>.value(value: sounds),
      ],
      child: MaterialApp.router(
        title: 'AdventQuiz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
