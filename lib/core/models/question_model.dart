class Question {
  final String id;
  final String quizId;
  final String questionText;
  final int questionNumber;
  final int marks; // marks awarded for a correct answer
  final String? imageUrl;
  final int timeLimitSeconds; // Time limit per question in seconds

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionNumber,
    this.marks = 1,
    this.imageUrl,
    this.timeLimitSeconds = 60, // Default 1 minute
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionText: json['question_text'] as String,
      questionNumber: json['question_number'] as int,
      marks: (json['marks'] as num?)?.toInt() ?? 1,
      imageUrl: json['image_url'] as String?,
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_number': questionNumber,
      'marks': marks,
      'image_url': imageUrl,
      'time_limit_seconds': timeLimitSeconds,
    };
  }
}

class Answer {
  final String id;
  final String questionId;
  final String answerText;
  final int answerNumber;
  final bool isCorrect;
  final String? explanation;
  final String? imageUrl;

  Answer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.answerNumber,
    required this.isCorrect,
    this.explanation,
    this.imageUrl,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      answerText: json['answer_text'] as String,
      answerNumber: json['answer_number'] as int,
      isCorrect: json['is_correct'] as bool,
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'answer_text': answerText,
      'answer_number': answerNumber,
      'is_correct': isCorrect,
      'explanation': explanation,
      'image_url': imageUrl,
    };
  }
}
