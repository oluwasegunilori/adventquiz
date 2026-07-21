import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quiz_pack.dart';
import '../models/room.dart';
import 'room_repository.dart';
import 'scoring.dart';

class FirestoreRoomRepository implements RoomRepository {
  FirestoreRoomRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'admin-restricted-operation' ||
          e.code == 'operation-not-allowed') {
        throw StateError(
          'Firebase Authentication is not ready. In the Firebase console for '
          'project "churchgamey": open Authentication → Get started → Sign-in '
          'method → enable Anonymous. Then retry.',
        );
      }
      rethrow;
    }
  }

  Future<String> _uniquePin() async {
    final rng = Random();
    for (var i = 0; i < 20; i++) {
      final pin = (100000 + rng.nextInt(900000)).toString();
      final snap = await _rooms.where('pin', isEqualTo: pin).limit(1).get();
      if (snap.docs.isEmpty) return pin;
    }
    throw StateError('Could not allocate a PIN');
  }

  @override
  Future<GameRoom> createRoom({
    required QuizPack pack,
    required String hostNickname,
  }) async {
    final uid = await ensureSignedIn();
    final pin = await _uniquePin();
    final doc = _rooms.doc();
    final now = DateTime.now();
    final host = RoomPlayer(
      uid: uid,
      nickname: hostNickname.trim().isEmpty ? 'Host' : hostNickname.trim(),
      score: 0,
      joinedAt: now,
      isHost: true,
    );
    final room = GameRoom(
      id: doc.id,
      pin: pin,
      hostUid: uid,
      packId: pack.id,
      packTitle: pack.title,
      questions: pack.questions,
      status: RoomStatus.lobby,
      currentIndex: 0,
      createdAt: now,
      players: [host],
    );
    final batch = _db.batch();
    batch.set(doc, room.toRoomJson());
    batch.set(doc.collection('players').doc(uid), host.toJson());
    await batch.commit();
    return room;
  }

  @override
  Future<GameRoom> joinRoom({
    required String pin,
    required String nickname,
  }) async {
    final uid = await ensureSignedIn();
    final snap =
        await _rooms.where('pin', isEqualTo: pin.trim()).limit(1).get();
    if (snap.docs.isEmpty) {
      throw StateError('No room found for PIN $pin');
    }
    final doc = snap.docs.first;
    final data = doc.data();
    if ((data['status'] as String?) != RoomStatus.lobby.wireName) {
      throw StateError('Game already started');
    }
    final player = RoomPlayer(
      uid: uid,
      nickname: nickname.trim().isEmpty ? 'Player' : nickname.trim(),
      score: 0,
      joinedAt: DateTime.now(),
    );
    await doc.reference.collection('players').doc(uid).set(player.toJson());
    return GameRoom.fromDoc(id: doc.id, data: data, players: [player]);
  }

  @override
  Stream<GameRoom?> watchRoom(String roomId) {
    final roomRef = _rooms.doc(roomId);
    late StreamController<GameRoom?> controller;
    DocumentSnapshot<Map<String, dynamic>>? roomSnap;
    QuerySnapshot<Map<String, dynamic>>? playerSnap;
    QuerySnapshot<Map<String, dynamic>>? answerSnap;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? roomSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? playerSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? answerSub;

    void emit() {
      if (roomSnap == null || playerSnap == null || answerSnap == null) return;
      if (!roomSnap!.exists || roomSnap!.data() == null) {
        controller.add(null);
        return;
      }
      final players =
          playerSnap!.docs.map((d) => RoomPlayer.fromJson(d.data())).toList();
      final answers =
          answerSnap!.docs.map((d) => PlayerAnswer.fromJson(d.data())).toList();
      controller.add(
        GameRoom.fromDoc(
          id: roomSnap!.id,
          data: roomSnap!.data()!,
          players: players,
          answers: answers,
        ),
      );
    }

    controller = StreamController<GameRoom?>(
      onListen: () {
        roomSub = roomRef.snapshots().listen((s) {
          roomSnap = s;
          emit();
        });
        playerSub = roomRef.collection('players').snapshots().listen((s) {
          playerSnap = s;
          emit();
        });
        answerSub = roomRef.collection('answers').snapshots().listen((s) {
          answerSnap = s;
          emit();
        });
      },
      onCancel: () async {
        await roomSub?.cancel();
        await playerSub?.cancel();
        await answerSub?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  Future<void> _assertHost(String roomId) async {
    final uid = await ensureSignedIn();
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists) throw StateError('Room not found');
    if (snap.data()!['hostUid'] != uid) {
      throw StateError('Only host can do that');
    }
  }

  @override
  Future<void> startGame(String roomId) async {
    await _assertHost(roomId);
    await _rooms.doc(roomId).update({
      'status': RoomStatus.question.wireName,
      'currentIndex': 0,
      'questionStartedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> revealQuestion(String roomId) async {
    await _assertHost(roomId);
    await _rooms.doc(roomId).update({
      'status': RoomStatus.reveal.wireName,
    });
  }

  @override
  Future<void> showLeaderboard(String roomId) async {
    await _assertHost(roomId);
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data()!;
    final index = (data['currentIndex'] as num).toInt();
    final questions = data['questions'] as List<dynamic>;
    final isLast = index >= questions.length - 1;
    await _rooms.doc(roomId).update({
      'status': isLast
          ? RoomStatus.finished.wireName
          : RoomStatus.leaderboard.wireName,
    });
  }

  @override
  Future<void> nextQuestion(String roomId) async {
    await _assertHost(roomId);
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data()!;
    final index = (data['currentIndex'] as num).toInt();
    final questions = data['questions'] as List<dynamic>;
    final next = index + 1;
    if (next >= questions.length) {
      await _rooms.doc(roomId).update({
        'status': RoomStatus.finished.wireName,
      });
    } else {
      await _rooms.doc(roomId).update({
        'status': RoomStatus.question.wireName,
        'currentIndex': next,
        'questionStartedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> endGame(String roomId) async {
    await _assertHost(roomId);
    await _rooms.doc(roomId).update({
      'status': RoomStatus.finished.wireName,
    });
  }

  @override
  Future<PlayerAnswer> submitAnswer({
    required String roomId,
    required int questionIndex,
    required String choiceId,
    required int responseMs,
  }) async {
    final uid = await ensureSignedIn();
    final roomRef = _rooms.doc(roomId);
    final answerId = '${questionIndex}_$uid';
    final answerRef = roomRef.collection('answers').doc(answerId);
    final playerRef = roomRef.collection('players').doc(uid);

    return _db.runTransaction((tx) async {
      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw StateError('Room not found');
      final data = roomSnap.data()!;
      if (data['status'] != RoomStatus.question.wireName) {
        throw StateError('Not accepting answers');
      }
      if ((data['currentIndex'] as num).toInt() != questionIndex) {
        throw StateError('Question mismatch');
      }
      final existing = await tx.get(answerRef);
      if (existing.exists) {
        return PlayerAnswer.fromJson(existing.data()!);
      }
      final questions = (data['questions'] as List<dynamic>)
          .map(
            (e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      final question = questions[questionIndex];
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
      tx.set(answerRef, answer.toJson());
      final playerSnap = await tx.get(playerRef);
      final currentScore =
          (playerSnap.data()?['score'] as num?)?.toInt() ?? 0;
      tx.update(playerRef, {'score': currentScore + points});
      return answer;
    });
  }
}
