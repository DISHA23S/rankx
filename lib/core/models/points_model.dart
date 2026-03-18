class UserPoints {
  final String id;
  final String userId;
  final int dailyPoints;
  final int weeklyPoints;
  final int totalPoints;
  final DateTime lastUpdated;

  UserPoints({
    required this.id,
    required this.userId,
    required this.dailyPoints,
    required this.weeklyPoints,
    required this.totalPoints,
    required this.lastUpdated,
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyPoints: json['daily_points'] as int? ?? 0,
      weeklyPoints: json['weekly_points'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_points': dailyPoints,
      'weekly_points': weeklyPoints,
      'total_points': totalPoints,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class UserAnswer {
  final String id;
  final String userId;
  final String quizId;
  final String questionId;
  final String? selectedAnswerId;
  final bool isCorrect;
  final DateTime answeredAt;
  final int timeSpentSeconds;

  UserAnswer({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.questionId,
    this.selectedAnswerId,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeSpentSeconds,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quizId: json['quiz_id'] as String,
      questionId: json['question_id'] as String,
      selectedAnswerId: json['selected_answer_id'] as String?,
      isCorrect: json['is_correct'] as bool,
      answeredAt: DateTime.parse(json['answered_at'] as String),
      timeSpentSeconds: json['time_spent_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
      'answered_at': answeredAt.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
    };
  }
}
