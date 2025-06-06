class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'card', 'upi', 'wallet', etc.
  final String displayName;
  final String? last4;
  final String? cardBrand;
  final String? expiryMonth;
  final String? expiryYear;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    this.last4,
    this.cardBrand,
    this.expiryMonth,
    this.expiryYear,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      userId: json['user_id'],
      type: json['card_type'] ?? 'card',
      displayName: json['card_holder_name'] ?? '',
      last4: json['card_number'],
      cardBrand: json['card_type'],
      expiryMonth: json['expiry_month'],
      expiryYear: json['expiry_year'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_type': type,
      'card_holder_name': displayName,
      'card_number': last4,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get maskedCardNumber => '**** **** **** $last4';
  String get expiryDate => '$expiryMonth/$expiryYear';
}
