import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_bootstrap.dart';
import 'app_router.dart';
import 'data/room_repository.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.init();
  final sounds = SoundService();
  await sounds.init();
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
