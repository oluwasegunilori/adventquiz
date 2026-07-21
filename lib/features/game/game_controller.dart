import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/room_repository.dart';
import '../../models/room.dart';
import '../../services/sound_service.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.repository,
    required this.roomId,
    required this.isHost,
    required this.sounds,
  });

  final RoomRepository repository;
  final String roomId;
  final bool isHost;
  final SoundService sounds;

  StreamSubscription<GameRoom?>? _sub;
  GameRoom? room;
  String? error;
  bool busy = false;
  Timer? _questionTimer;
  int remainingMs = 0;
  String? selectedChoiceId;
  int? lastPoints;
  bool? lastCorrect;
  int _lastPlayerCount = 0;

  String? get uid => repository.currentUid;

  bool get isMeHost =>
      room != null && uid != null && room!.hostUid == uid;

  Future<void> start() async {
    await repository.ensureSignedIn();
    _sub = repository.watchRoom(roomId).listen((value) {
      final previous = room;
      room = value;
      if (value == null) {
        error = 'Room not found';
        notifyListeners();
        return;
      }
      _handleTransitions(previous, value);
      _syncTimer(previous, value);
      if (previous?.currentIndex != value.currentIndex ||
          previous?.status != value.status) {
        selectedChoiceId = null;
        lastPoints = null;
        lastCorrect = null;
      }
      final mine =
          uid == null ? null : value.answerFor(uid!, value.currentIndex);
      if (mine != null) {
        selectedChoiceId = mine.choiceId;
        lastPoints = mine.points;
        lastCorrect = mine.correct;
      }
      notifyListeners();
    }, onError: (Object e) {
      error = e.toString();
      notifyListeners();
    });
  }

  void _handleTransitions(GameRoom? previous, GameRoom next) {
    if (previous == null) {
      _lastPlayerCount = next.players.length;
      return;
    }

    if (next.players.length > _lastPlayerCount &&
        next.status == RoomStatus.lobby) {
      sounds.play(GameSound.join);
    }
    _lastPlayerCount = next.players.length;

    if (previous.status == next.status &&
        previous.currentIndex == next.currentIndex) {
      return;
    }

    switch (next.status) {
      case RoomStatus.question:
        sounds.resetTickGate();
        sounds.play(GameSound.start);
      case RoomStatus.reveal:
        _playQuestionCompleteSounds(next);
      case RoomStatus.leaderboard:
        sounds.play(GameSound.leaderboard);
      case RoomStatus.finished:
        sounds.play(GameSound.podium);
      case RoomStatus.lobby:
        break;
    }
  }

  void _playQuestionCompleteSounds(GameRoom next) {
    sounds.play(GameSound.reveal);
    final mine =
        uid == null ? null : next.answerFor(uid!, next.currentIndex);
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mine != null) {
        sounds.play(mine.correct ? GameSound.correct : GameSound.wrong);
      }
    });
    // Kahoot-style scoreboard sting after the personal result.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (room?.status == RoomStatus.reveal ||
          room?.status == RoomStatus.leaderboard) {
        sounds.play(GameSound.leaderboard);
      }
    });
  }

  void _syncTimer(GameRoom? previous, GameRoom room) {
    if (room.status != RoomStatus.question) {
      _questionTimer?.cancel();
      remainingMs = 0;
      return;
    }
    final q = room.currentQuestion;
    if (q == null || room.questionStartedAt == null) return;
    final startedFresh = previous?.questionStartedAt != room.questionStartedAt ||
        previous?.status != RoomStatus.question;
    if (!startedFresh && _questionTimer != null) return;

    _questionTimer?.cancel();
    void tick() {
      final elapsed =
          DateTime.now().difference(room.questionStartedAt!).inMilliseconds;
      final total = q.timeLimitSec * 1000;
      remainingMs = (total - elapsed).clamp(0, total);
      sounds.maybeTick(remainingMs);
      notifyListeners();
      if (remainingMs <= 0 &&
          isHost &&
          this.room?.status == RoomStatus.question) {
        _questionTimer?.cancel();
        reveal();
      }
    }

    tick();
    _questionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      tick();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> continueAfterReveal() {
    final current = room;
    if (current == null) return Future.value();
    final isLast = current.currentIndex >= current.questions.length - 1;
    if (isLast) {
      return _run(() => repository.endGame(roomId));
    }
    return _run(() => repository.nextQuestion(roomId));
  }

  Future<void> startGame() => _run(() => repository.startGame(roomId));

  Future<void> reveal() => _run(() => repository.revealQuestion(roomId));

  Future<void> showLeaderboard() =>
      _run(() => repository.showLeaderboard(roomId));

  Future<void> nextQuestion() => _run(() => repository.nextQuestion(roomId));

  Future<void> endGame() => _run(() => repository.endGame(roomId));

  Future<void> submitAnswer(String choiceId) async {
    final current = room;
    if (current == null || current.status != RoomStatus.question) return;
    if (selectedChoiceId != null) return;
    selectedChoiceId = choiceId;
    notifyListeners();
    final started = current.questionStartedAt ?? DateTime.now();
    final ms = DateTime.now().difference(started).inMilliseconds;
    try {
      final answer = await repository.submitAnswer(
        roomId: roomId,
        questionIndex: current.currentIndex,
        choiceId: choiceId,
        responseMs: ms,
      );
      lastPoints = answer.points;
      lastCorrect = answer.correct;
    } catch (e) {
      selectedChoiceId = null;
      error = e.toString().replaceFirst('Bad state: ', '');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }
}
