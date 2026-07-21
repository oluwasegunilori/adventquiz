import '../models/quiz_pack.dart';
import '../models/room.dart';

abstract class RoomRepository {
  Future<String> ensureSignedIn();

  String? get currentUid;

  Future<GameRoom> createRoom({
    required QuizPack pack,
    required String hostNickname,
  });

  Future<GameRoom> joinRoom({
    required String pin,
    required String nickname,
  });

  Stream<GameRoom?> watchRoom(String roomId);

  Future<void> startGame(String roomId);

  Future<void> revealQuestion(String roomId);

  Future<void> showLeaderboard(String roomId);

  Future<void> nextQuestion(String roomId);

  Future<void> endGame(String roomId);

  Future<PlayerAnswer> submitAnswer({
    required String roomId,
    required int questionIndex,
    required String choiceId,
    required int responseMs,
  });
}
