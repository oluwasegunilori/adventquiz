import 'quiz_pack.dart';

enum RoomStatus { lobby, question, reveal, leaderboard, finished }

extension RoomStatusX on RoomStatus {
  String get wireName => name;

  static RoomStatus fromWire(String value) {
    return RoomStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoomStatus.lobby,
    );
  }
}

class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.nickname,
    required this.score,
    required this.joinedAt,
    this.isHost = false,
  });

  final String uid;
  final String nickname;
  final int score;
  final DateTime joinedAt;
  final bool isHost;

  RoomPlayer copyWith({int? score}) {
    return RoomPlayer(
      uid: uid,
      nickname: nickname,
      score: score ?? this.score,
      joinedAt: joinedAt,
      isHost: isHost,
    );
  }

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isHost: json['isHost'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'score': score,
        'joinedAt': joinedAt.toIso8601String(),
        'isHost': isHost,
      };
}

class PlayerAnswer {
  const PlayerAnswer({
    required this.uid,
    required this.questionIndex,
    required this.choiceId,
    required this.correct,
    required this.ms,
    required this.points,
  });

  final String uid;
  final int questionIndex;
  final String choiceId;
  final bool correct;
  final int ms;
  final int points;

  factory PlayerAnswer.fromJson(Map<String, dynamic> json) {
    return PlayerAnswer(
      uid: json['uid'] as String,
      questionIndex: (json['questionIndex'] as num).toInt(),
      choiceId: json['choiceId'] as String,
      correct: json['correct'] as bool,
      ms: (json['ms'] as num).toInt(),
      points: (json['points'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'questionIndex': questionIndex,
        'choiceId': choiceId,
        'correct': correct,
        'ms': ms,
        'points': points,
      };
}

class GameRoom {
  const GameRoom({
    required this.id,
    required this.pin,
    required this.hostUid,
    required this.packId,
    required this.packTitle,
    required this.questions,
    required this.status,
    required this.currentIndex,
    required this.createdAt,
    this.questionStartedAt,
    this.players = const [],
    this.answers = const [],
  });

  final String id;
  final String pin;
  final String hostUid;
  final String packId;
  final String packTitle;
  final List<QuizQuestion> questions;
  final RoomStatus status;
  final int currentIndex;
  final DateTime createdAt;
  final DateTime? questionStartedAt;
  final List<RoomPlayer> players;
  final List<PlayerAnswer> answers;

  QuizQuestion? get currentQuestion {
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  bool get isFinished => status == RoomStatus.finished;

  List<RoomPlayer> get rankedPlayers {
    final sorted = [...players]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.joinedAt.compareTo(b.joinedAt);
      });
    return sorted;
  }

  PlayerAnswer? answerFor(String uid, int questionIndex) {
    for (final a in answers) {
      if (a.uid == uid && a.questionIndex == questionIndex) return a;
    }
    return null;
  }

  GameRoom copyWith({
    RoomStatus? status,
    int? currentIndex,
    DateTime? questionStartedAt,
    List<RoomPlayer>? players,
    List<PlayerAnswer>? answers,
    bool clearQuestionStartedAt = false,
  }) {
    return GameRoom(
      id: id,
      pin: pin,
      hostUid: hostUid,
      packId: packId,
      packTitle: packTitle,
      questions: questions,
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      createdAt: createdAt,
      questionStartedAt: clearQuestionStartedAt
          ? null
          : (questionStartedAt ?? this.questionStartedAt),
      players: players ?? this.players,
      answers: answers ?? this.answers,
    );
  }

  Map<String, dynamic> toRoomJson() => {
        'pin': pin,
        'hostUid': hostUid,
        'packId': packId,
        'packTitle': packTitle,
        'questions': questions.map((q) => q.toJson()).toList(),
        'status': status.wireName,
        'currentIndex': currentIndex,
        'createdAt': createdAt.toIso8601String(),
        'questionStartedAt': questionStartedAt?.toIso8601String(),
      };

  factory GameRoom.fromDoc({
    required String id,
    required Map<String, dynamic> data,
    List<RoomPlayer> players = const [],
    List<PlayerAnswer> answers = const [],
  }) {
    final questions = (data['questions'] as List<dynamic>? ?? [])
        .map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return GameRoom(
      id: id,
      pin: data['pin'] as String,
      hostUid: data['hostUid'] as String,
      packId: data['packId'] as String,
      packTitle: data['packTitle'] as String? ?? '',
      questions: questions,
      status: RoomStatusX.fromWire(data['status'] as String? ?? 'lobby'),
      currentIndex: (data['currentIndex'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(data['createdAt'] as String),
      questionStartedAt: data['questionStartedAt'] != null
          ? DateTime.parse(data['questionStartedAt'] as String)
          : null,
      players: players,
      answers: answers,
    );
  }
}
