class QuizChoice {
  const QuizChoice({required this.id, required this.text});

  final String id;
  final String text;

  factory QuizChoice.fromJson(Map<String, dynamic> json) {
    return QuizChoice(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.choices,
    required this.correctId,
    this.verseRef,
    this.timeLimitSec = 20,
  });

  final String id;
  final String text;
  final List<QuizChoice> choices;
  final String correctId;
  final String? verseRef;
  final int timeLimitSec;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>)
        .map((e) => QuizChoice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return QuizQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      choices: choices,
      correctId: json['correctId'] as String,
      verseRef: json['verseRef'] as String?,
      timeLimitSec: (json['timeLimitSec'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'choices': choices.map((c) => c.toJson()).toList(),
        'correctId': correctId,
        'verseRef': verseRef,
        'timeLimitSec': timeLimitSec,
      };
}

class QuizPack {
  const QuizPack({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final List<QuizQuestion> questions;

  factory QuizPack.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>)
        .map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return QuizPack(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
