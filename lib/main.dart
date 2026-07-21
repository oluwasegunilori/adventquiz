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

  // Paint first frame immediately — never block UI on Firebase.
  final sounds = SoundService();
  unawaited(sounds.init().catchError((Object e, StackTrace st) {
    debugPrint('Sound init error: $e\n$st');
  }));

  runApp(
    AdventQuizApp(
      initialBootstrap: AppBootstrap(
        repository: LocalRoomRepository(),
        usingFirebase: false,
      ),
      sounds: sounds,
    ),
  );
}

class AdventQuizApp extends StatefulWidget {
  const AdventQuizApp({
    super.key,
    required this.initialBootstrap,
    required this.sounds,
  });

  final AppBootstrap initialBootstrap;
  final SoundService sounds;

  @override
  State<AdventQuizApp> createState() => _AdventQuizAppState();
}

class _AdventQuizAppState extends State<AdventQuizApp> {
  late AppBootstrap _bootstrap = widget.initialBootstrap;

  @override
  void initState() {
    super.initState();
    unawaited(_upgradeFirebase());
  }

  Future<void> _upgradeFirebase() async {
    try {
      final next = await AppBootstrap.init().timeout(
        const Duration(seconds: 6),
        onTimeout: () => _bootstrap,
      );
      if (!mounted) return;
      if (next.usingFirebase != _bootstrap.usingFirebase) {
        setState(() => _bootstrap = next);
      }
    } catch (e, st) {
      debugPrint('Background Firebase upgrade failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = createRouter(usingFirebase: _bootstrap.usingFirebase);
    return MultiProvider(
      providers: [
        Provider<RoomRepository>.value(value: _bootstrap.repository),
        ChangeNotifierProvider<SoundService>.value(value: widget.sounds),
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
