class SubscriptionPlan {
  final String id;
  final String name;
  final String code; // internal code used in subscriptions table
  final String? description;
  final int durationDays;
  final double price;
  final int points;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.durationDays,
    required this.price,
    required this.points,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      durationDays: (json['duration_days'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      points: (json['points'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'duration_days': durationDays,
      'price': price,
      'points': points,
      'is_active': isActive,
    };
  }
}


