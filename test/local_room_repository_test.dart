import 'package:adventquiz/data/local_room_repository.dart';
import 'package:adventquiz/data/pack_loader.dart';
import 'package:adventquiz/models/room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('host creates room and second client joins by PIN', () async {
    final host = LocalRoomRepository();
    final player = LocalRoomRepository();
    final packs = await PackLoader().loadAll();
    final pack = packs.first;

    final created = await host.createRoom(pack: pack, hostNickname: 'Host');
    expect(created.pin.length, 6);
    expect(created.status, RoomStatus.lobby);

    final joined = await player.joinRoom(pin: created.pin, nickname: 'Ada');
    expect(joined.id, created.id);

    final seen = await host.watchRoom(created.id).first;
    expect(seen!.players.length, 2);
    expect(seen.players.any((p) => p.nickname == 'Ada'), isTrue);
  });

  test('answer awards points and advances via host controls', () async {
    final host = LocalRoomRepository();
    final player = LocalRoomRepository();
    final packs = await PackLoader().loadAll();
    final room = await host.createRoom(pack: packs.first, hostNickname: 'Host');
    await player.joinRoom(pin: room.pin, nickname: 'Ada');
    await host.startGame(room.id);

    final q = room.questions.first;
    final answer = await player.submitAnswer(
      roomId: room.id,
      questionIndex: 0,
      choiceId: q.correctId,
      responseMs: 500,
    );
    expect(answer.correct, isTrue);
    expect(answer.points, greaterThan(0));

    await host.revealQuestion(room.id);
    await host.showLeaderboard(room.id);
    final after = await host.watchRoom(room.id).first;
    expect(after!.status, RoomStatus.leaderboard);
    expect(after.players.firstWhere((p) => p.nickname == 'Ada').score, greaterThan(0));
  });
}
