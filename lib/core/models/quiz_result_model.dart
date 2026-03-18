class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final int totalQuestions;
  final int correctAnswers;
  final int marksObtained;
  final int totalMarks;
  final int timeTakenSeconds;
  final int maxTimeSeconds;
  final double accuracy;
  final DateTime attemptedAt;
  final List<QuestionResult> questionResults;

  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.marksObtained,
    required this.totalMarks,
    required this.timeTakenSeconds,
    required this.maxTimeSeconds,
    required this.accuracy,
    required this.attemptedAt,
    this.questionResults = const [],
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quizId: json['quiz_id'] as String,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      marksObtained: (json['marks_obtained'] as num?)?.toInt() ?? 0,
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['time_taken_seconds'] as num?)?.toInt() ?? 0,
      maxTimeSeconds: (json['max_time_seconds'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
      questionResults: (json['question_results'] as List?)
              ?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'time_taken_seconds': timeTakenSeconds,
      'max_time_seconds': maxTimeSeconds,
      'accuracy': accuracy,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }

  // Calculate performance percentage
  double get performancePercentage {
    if (totalMarks == 0) return 0;
    return (marksObtained / totalMarks) * 100;
  }

  // Calculate time efficiency
  double get timeEfficiency {
    if (maxTimeSeconds == 0) return 0;
    return ((maxTimeSeconds - timeTakenSeconds) / maxTimeSeconds) * 100;
  }
}

class QuestionResult {
  final String questionId;
  final String questionText;
  final String? selectedAnswer;
  final String? correctAnswer;
  final bool isCorrect;
  final int marks;
  final int timeSpentSeconds;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    this.selectedAnswer,
    this.correctAnswer,
    required this.isCorrect,
    required this.marks,
    required this.timeSpentSeconds,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      selectedAnswer: json['selected_answer'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      isCorrect: json['is_correct'] as bool,
      marks: (json['marks'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'selected_answer': selectedAnswer,
      'correct_answer': correctAnswer,
      'is_correct': isCorrect,
      'marks': marks,
      'time_spent_seconds': timeSpentSeconds,
    };
  }
}
