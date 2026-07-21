import 'package:go_router/go_router.dart';

import 'features/game/game_room_screen.dart';
import 'features/home/home_screen.dart';
import 'features/host/host_setup_screen.dart';
import 'features/player/join_screen.dart';

GoRouter createRouter({required bool usingFirebase}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(usingFirebase: usingFirebase),
      ),
      GoRoute(
        path: '/host',
        builder: (context, state) => const HostSetupScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final host = state.uri.queryParameters['host'] == '1';
          return GameRoomScreen(roomId: roomId, isHost: host);
        },
      ),
    ],
  );
}
