import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/quiz_pack.dart';
import '../models/room.dart';
import 'join_messages.dart';
import 'room_repository.dart';
import 'scoring.dart';

/// Persists rooms in SharedPreferences (localStorage on web) so multiple
/// browser tabs on the same device can join via PIN without Firebase.
class LocalRoomRepository implements RoomRepository {
  LocalRoomRepository();

  static const _roomPrefix = 'adventquiz_room_';
  static const _pinIndexKey = 'adventquiz_pin_index';

  String? _uid;
  final Map<String, StreamController<GameRoom?>> _controllers = {};
  final Map<String, Timer> _pollers = {};
  final Map<String, String> _lastJson = {};

  @override
  String? get currentUid => _uid;

  /// Per-tab identity (not persisted) so host + join work in two browser tabs.
  @override
  Future<String> ensureSignedIn() async {
    _uid ??= const Uuid().v4();
    return _uid!;
  }

  Future<Map<String, String>> _pinIndex(SharedPreferences prefs) async {
    final raw = prefs.getString(_pinIndexKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _savePinIndex(
    SharedPreferences prefs,
    Map<String, String> index,
  ) async {
    await prefs.setString(_pinIndexKey, jsonEncode(index));
  }

  String _roomKey(String roomId) => '$_roomPrefix$roomId';

  Future<GameRoom?> _loadRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roomKey(roomId));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final players = (data['players'] as List<dynamic>? ?? [])
        .map((e) => RoomPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final answers = (data['answers'] as List<dynamic>? ?? [])
        .map((e) => PlayerAnswer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return GameRoom.fromDoc(
      id: roomId,
      data: data,
      players: players,
      answers: answers,
    );
  }

  Future<void> _saveRoom(GameRoom room) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      ...room.toRoomJson(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'answers': room.answers.map((a) => a.toJson()).toList(),
    };
    final encoded = jsonEncode(payload);
    await prefs.setString(_roomKey(room.id), encoded);
    final index = await _pinIndex(prefs);
    index[room.pin] = room.id;
    await _savePinIndex(prefs, index);
    _lastJson[room.id] = encoded;
    _emit(room.id, room);
  }

  Future<String> _generatePin(SharedPreferences prefs) async {
    final rng = Random();
    final index = await _pinIndex(prefs);
    for (var i = 0; i < 30; i++) {
      final pin = (100000 + rng.nextInt(900000)).toString();
      if (!index.containsKey(pin)) return pin;
    }
    throw StateError('Could not allocate a PIN');
  }

  void _emit(String roomId, GameRoom? room) {
    final c = _controllers[roomId];
    if (c != null && !c.isClosed) c.add(room);
  }

  void _ensurePolling(String roomId) {
    if (_pollers.containsKey(roomId)) return;
    _pollers[roomId] = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      final room = await _loadRoom(roomId);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_roomKey(roomId));
      if (raw != _lastJson[roomId]) {
        _lastJson[roomId] = raw ?? '';
        _emit(roomId, room);
      }
    });
  }

  GameRoom _requireLoaded(GameRoom? room) {
    if (room == null) throw StateError('Room not found');
    return room;
  }

  @override
  Future<GameRoom> createRoom({
    required QuizPack pack,
    required String hostNickname,
  }) async {
    final uid = await ensureSignedIn();
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();
    final now = DateTime.now();
    final host = RoomPlayer(
      uid: uid,
      nickname: hostNickname.trim().isEmpty ? 'Host' : hostNickname.trim(),
      score: 0,
      joinedAt: now,
      isHost: true,
    );
    final room = GameRoom(
      id: id,
      pin: await _generatePin(prefs),
      hostUid: uid,
      packId: pack.id,
      packTitle: pack.title,
      questions: pack.questions,
      status: RoomStatus.lobby,
      currentIndex: 0,
      createdAt: now,
      players: [host],
    );
    await _saveRoom(room);
    return room;
  }

  @override
  Future<GameRoom> joinRoom({
    required String pin,
    required String nickname,
  }) async {
    final uid = await ensureSignedIn();
    final prefs = await SharedPreferences.getInstance();
    final index = await _pinIndex(prefs);
    final roomId = index[pin.trim()];
    if (roomId == null) {
      throw StateError(
        'No room found for PIN $pin. '
        'Local mode only works across tabs on the same browser/device. '
        'Configure Firebase for true online multiplayer.',
      );
    }
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.players.any((p) => p.uid == uid)) return room;
    if (room.status != RoomStatus.lobby) {
      throw StateError(joinClosedMessage(room.status));
    }
    final player = RoomPlayer(
      uid: uid,
      nickname: nickname.trim().isEmpty ? 'Player' : nickname.trim(),
      score: 0,
      joinedAt: DateTime.now(),
    );
    final updated = room.copyWith(players: [...room.players, player]);
    await _saveRoom(updated);
    return updated;
  }

  @override
  Stream<GameRoom?> watchRoom(String roomId) {
    final controller = _controllers.putIfAbsent(
      roomId,
      () => StreamController<GameRoom?>.broadcast(
        onCancel: () {
          if (!(_controllers[roomId]?.hasListener ?? true)) {
            _pollers.remove(roomId)?.cancel();
          }
        },
      ),
    );
    _ensurePolling(roomId);
    scheduleMicrotask(() async {
      final room = await _loadRoom(roomId);
      _emit(roomId, room);
    });
    return controller.stream;
  }

  @override
  Future<void> startGame(String roomId) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.hostUid != uid) throw StateError('Only host can start');
    await _saveRoom(
      room.copyWith(
        status: RoomStatus.question,
        currentIndex: 0,
        questionStartedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> revealQuestion(String roomId) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.hostUid != uid) throw StateError('Only host can reveal');
    await _saveRoom(room.copyWith(status: RoomStatus.reveal));
  }

  @override
  Future<void> showLeaderboard(String roomId) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.hostUid != uid) throw StateError('Only host can continue');
    final isLast = room.currentIndex >= room.questions.length - 1;
    await _saveRoom(
      room.copyWith(
        status: isLast ? RoomStatus.finished : RoomStatus.leaderboard,
      ),
    );
  }

  @override
  Future<void> nextQuestion(String roomId) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.hostUid != uid) throw StateError('Only host can advance');
    final next = room.currentIndex + 1;
    if (next >= room.questions.length) {
      await _saveRoom(room.copyWith(status: RoomStatus.finished));
    } else {
      await _saveRoom(
        room.copyWith(
          status: RoomStatus.question,
          currentIndex: next,
          questionStartedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> endGame(String roomId) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.hostUid != uid) throw StateError('Only host can end');
    await _saveRoom(room.copyWith(status: RoomStatus.finished));
  }

  @override
  Future<PlayerAnswer> submitAnswer({
    required String roomId,
    required int questionIndex,
    required String choiceId,
    required int responseMs,
  }) async {
    final uid = await ensureSignedIn();
    final room = _requireLoaded(await _loadRoom(roomId));
    if (room.status != RoomStatus.question) {
      throw StateError('Not accepting answers');
    }
    if (room.currentIndex != questionIndex) {
      throw StateError('Question mismatch');
    }
    final existing = room.answerFor(uid, questionIndex);
    if (existing != null) return existing;

    final question = room.questions[questionIndex];
    final correct = choiceId == question.correctId;
    final points = Scoring.pointsFor(
      correct: correct,
      responseMs: responseMs,
      timeLimitSec: question.timeLimitSec,
    );
    final answer = PlayerAnswer(
      uid: uid,
      questionIndex: questionIndex,
      choiceId: choiceId,
      correct: correct,
      ms: responseMs,
      points: points,
    );
    final players = room.players.map((p) {
      if (p.uid != uid) return p;
      return p.copyWith(score: p.score + points);
    }).toList();
    await _saveRoom(
      room.copyWith(
        players: players,
        answers: [...room.answers, answer],
      ),
    );
    return answer;
  }
}
