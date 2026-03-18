class User {
  final String id;
  final String email;
  final String? phone;
  final String role; // 'admin' or 'user'
  final String? name;
  final String? profileImage;
  final bool emailVerified;
  final bool? termsAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    this.name,
    this.profileImage,
    this.emailVerified = false,
    this.termsAccepted,
    this.termsAcceptedAt,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      name: json['name'] as String?,
      profileImage: json['profile_image'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      termsAccepted: json['terms_accepted'] as bool?,
      termsAcceptedAt:
          json['terms_accepted_at'] != null
              ? DateTime.parse(json['terms_accepted_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin:
          json['last_login'] != null
              ? DateTime.parse(json['last_login'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'name': name,
      'profile_image': profileImage,
      'email_verified': emailVerified,
      'terms_accepted': termsAccepted,
      'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? role,
    String? name,
    String? profileImage,
    bool? emailVerified,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      emailVerified: emailVerified ?? this.emailVerified,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
