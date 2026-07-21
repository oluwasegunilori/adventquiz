import 'package:adventquiz/app_bootstrap.dart';
import 'package:adventquiz/data/local_room_repository.dart';
import 'package:adventquiz/main.dart';
import 'package:adventquiz/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows AdventQuiz brand and actions', (tester) async {
    final sounds = SoundService();
    final bootstrap = AppBootstrap(
      repository: LocalRoomRepository(),
      usingFirebase: false,
    );
    await tester.pumpWidget(
      AdventQuizApp(initialBootstrap: bootstrap, sounds: sounds),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('AdventQuiz'), findsOneWidget);
    expect(find.text('Host a game'), findsOneWidget);
    expect(find.text('Join with PIN'), findsOneWidget);
  });
}
