class Agreement {
  final String id;
  final String title;
  final String content;
  final String? documentUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agreement({
    required this.id,
    required this.title,
    required this.content,
    this.documentUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Agreement.fromJson(Map<String, dynamic> json) {
    return Agreement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      documentUrl: json['document_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'document_url': documentUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class UserAgreement {
  final String id;
  final String userId;
  final String agreementId;
  final bool accepted;
  final DateTime acceptedAt;

  UserAgreement({
    required this.id,
    required this.userId,
    required this.agreementId,
    required this.accepted,
    required this.acceptedAt,
  });

  factory UserAgreement.fromJson(Map<String, dynamic> json) {
    return UserAgreement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      agreementId: json['agreement_id'] as String,
      accepted: json['accepted'] as bool,
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'agreement_id': agreementId,
      'accepted': accepted,
      'accepted_at': acceptedAt.toIso8601String(),
    };
  }
}
