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
  Timer? _revealGrace;
  int remainingMs = 0;
  String? selectedChoiceId;
  int? lastPoints;
  bool? lastCorrect;
  /// True when a tap was locked in locally but the server rejected it as late.
  bool answerTooLate = false;
  int _lastPlayerCount = 0;

  String? get uid => repository.currentUid;

  bool get isMeHost =>
      room != null && uid != null && room!.hostUid == uid;

  bool get answersLocked =>
      room?.status != RoomStatus.question ||
      remainingMs <= 0 ||
      selectedChoiceId != null;

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
      // Only wipe selection when the question changes — keep it through reveal
      // so late/rejected taps can still show a clear message.
      if (previous?.currentIndex != value.currentIndex) {
        selectedChoiceId = null;
        lastPoints = null;
        lastCorrect = null;
        answerTooLate = false;
      }
      final mine =
          uid == null ? null : value.answerFor(uid!, value.currentIndex);
      if (mine != null) {
        selectedChoiceId = mine.choiceId;
        lastPoints = mine.points;
        lastCorrect = mine.correct;
        answerTooLate = false;
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
      _syncMusic(next.status);
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

    _syncMusic(next.status);

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

  void _syncMusic(RoomStatus status) {
    switch (status) {
      case RoomStatus.lobby:
        unawaited(sounds.setMusic(MusicBed.lounge));
      case RoomStatus.question:
        // Keep questions clear for ticks / focus.
        unawaited(sounds.setMusic(MusicBed.none));
      case RoomStatus.reveal:
      case RoomStatus.leaderboard:
        unawaited(sounds.setMusic(MusicBed.lounge));
      case RoomStatus.finished:
        unawaited(sounds.setMusic(MusicBed.celebration));
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
      _revealGrace?.cancel();
      _revealGrace = null;
      remainingMs = 0;
      return;
    }
    final q = room.currentQuestion;
    if (q == null || room.questionStartedAt == null) return;
    final startedFresh = previous?.questionStartedAt != room.questionStartedAt ||
        previous?.status != RoomStatus.question;
    if (!startedFresh && _questionTimer != null) return;

    _questionTimer?.cancel();
    _revealGrace?.cancel();
    _revealGrace = null;

    void tick() {
      final elapsed =
          DateTime.now().difference(room.questionStartedAt!).inMilliseconds;
      final total = q.timeLimitSec * 1000;
      remainingMs = (total - elapsed).clamp(0, total);
      sounds.maybeTick(remainingMs);
      notifyListeners();
      if (remainingMs <= 0 &&
          isHost &&
          this.room?.status == RoomStatus.question &&
          _revealGrace == null) {
        // Short grace so in-flight submits can land before reveal.
        _revealGrace = Timer(const Duration(milliseconds: 900), () {
          if (this.room?.status == RoomStatus.question) {
            reveal();
          }
        });
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
    if (remainingMs <= 0) {
      answerTooLate = true;
      notifyListeners();
      return;
    }
    selectedChoiceId = choiceId;
    answerTooLate = false;
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
      answerTooLate = false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Bad state: ', '');
      // Keep the local selection so reveal can say "too late" instead of
      // "you did not answer" when the host already flipped to reveal.
      if (msg.contains('Not accepting answers') ||
          msg.contains('Question mismatch')) {
        answerTooLate = true;
        error = null;
      } else {
        selectedChoiceId = null;
        error = msg;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _questionTimer?.cancel();
    _revealGrace?.cancel();
    super.dispose();
  }
}
