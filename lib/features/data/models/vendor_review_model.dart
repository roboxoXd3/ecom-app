class VendorReview {
  final String id;
  final String vendorId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorReview({
    required this.id,
    required this.vendorId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorReview.fromJson(Map<String, dynamic> json) {
    return VendorReview(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Anonymous',
      userAvatar: json['user_avatar'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorReview copyWith({
    String? id,
    String? vendorId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorReview(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayRating => rating.toStringAsFixed(1);

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
