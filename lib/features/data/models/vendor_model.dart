class Vendor {
  final String id;
  final String? userId;
  final String businessName;
  final String? businessDescription;
  final String? businessLogo;
  final String businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final VendorStatus status;
  final bool isFeatured;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.id,
    this.userId,
    required this.businessName,
    this.businessDescription,
    this.businessLogo,
    required this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    required this.status,
    required this.isFeatured,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      businessName: json['business_name']?.toString() ?? '',
      businessDescription: json['business_description']?.toString(),
      businessLogo: json['business_logo']?.toString(),
      businessEmail: json['business_email']?.toString() ?? '',
      businessPhone: json['business_phone']?.toString(),
      businessAddress: json['business_address']?.toString(),
      status:
          json['status'] != null
              ? VendorStatus.fromString(json['status'].toString())
              : VendorStatus.pending,
      isFeatured: json['is_featured'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_description': businessDescription,
      'business_logo': businessLogo,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'status': status.value,
      'is_featured': isFeatured,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Vendor copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessDescription,
    String? businessLogo,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    VendorStatus? status,
    bool? isFeatured,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessLogo: businessLogo ?? this.businessLogo,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayRating {
    if (totalReviews == 0) return 'No reviews yet';
    return '${averageRating.toStringAsFixed(1)} ⭐ ($totalReviews reviews)';
  }

  bool get isApproved => status == VendorStatus.approved;
  bool get isPending => status == VendorStatus.pending;
  bool get isRejected => status == VendorStatus.rejected;
  bool get isSuspended => status == VendorStatus.suspended;
}

enum VendorStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended');

  const VendorStatus(this.value);
  final String value;

  static VendorStatus fromString(String value) {
    return VendorStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VendorStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case VendorStatus.pending:
        return 'Pending Approval';
      case VendorStatus.approved:
        return 'Approved';
      case VendorStatus.rejected:
        return 'Rejected';
      case VendorStatus.suspended:
        return 'Suspended';
    }
  }
}
