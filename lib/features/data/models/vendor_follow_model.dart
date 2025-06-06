class VendorFollow {
  final String id;
  final String userId;
  final String vendorId;
  final DateTime createdAt;

  VendorFollow({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.createdAt,
  });

  factory VendorFollow.fromJson(Map<String, dynamic> json) {
    return VendorFollow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorId: json['vendor_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VendorFollow copyWith({
    String? id,
    String? userId,
    String? vendorId,
    DateTime? createdAt,
  }) {
    return VendorFollow(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
