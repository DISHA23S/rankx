class Quiz {
  final String id;
  final String adminId;
  final String title;
  final String? description;
  final String category;
  final int totalQuestions;
  final int durationSeconds;
  final int pointsCost; // points required to unlock this quiz
  final int totalMarks; // sum of question marks
  // Legacy money fields (kept for backward compatibility)
  final double? price;
  final bool isPaid;
  final String status; // 'draft', 'published', 'archived'
  final DateTime createdAt;
  final DateTime? publishedAt;
  final int? difficulty; // 1-5 scale
  final String? thumbnailUrl;

  Quiz({
    required this.id,
    required this.adminId,
    required this.title,
    this.description,
    required this.category,
    required this.totalQuestions,
    required this.durationSeconds,
    this.pointsCost = 0,
    this.totalMarks = 0,
    this.price,
    this.isPaid = false,
    this.status = 'draft',
    required this.createdAt,
    this.publishedAt,
    this.difficulty,
    this.thumbnailUrl,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final pointsCost = (json['points_cost'] as num?)?.toInt();
    final totalMarks = (json['total_marks'] as num?)?.toInt();
    return Quiz(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      totalQuestions: json['total_questions'] as int,
      durationSeconds: json['duration_seconds'] as int,
      pointsCost: pointsCost ?? 0,
      totalMarks: totalMarks ?? 0,
      price: (json['price'] as num?)?.toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      difficulty: json['difficulty'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'title': title,
      'description': description,
      'category': category,
      'total_questions': totalQuestions,
      'duration_seconds': durationSeconds,
      'points_cost': pointsCost,
      'total_marks': totalMarks,
      'price': price,
      'is_paid': isPaid,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'difficulty': difficulty,
      'thumbnail_url': thumbnailUrl,
    };
  }
}
