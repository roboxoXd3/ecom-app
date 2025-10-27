class Review {
  final String id;
  final String productId;
  final String userId;
  final String? orderId;
  final int rating;
  final String title;
  final String content;
  final List<String> images;
  final bool verifiedPurchase;
  final int helpfulCount;
  final int reportedCount;
  final String status;
  final String? vendorResponse;
  final DateTime? vendorResponseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper method to parse string lists from various data structures
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];

    try {
      if (data is List) {
        return data.map((item) => item.toString()).toList();
      } else if (data is Map<String, dynamic>) {
        return data.keys.toList();
      } else if (data is String) {
        // Handle comma-separated string
        return data
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing string list: $e');
      return [];
    }
  }

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.orderId,
    required this.rating,
    required this.title,
    required this.content,
    required this.images,
    required this.verifiedPurchase,
    required this.helpfulCount,
    required this.reportedCount,
    required this.status,
    this.vendorResponse,
    this.vendorResponseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      orderId: json['order_id'],
      rating: json['rating'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      images: _parseStringList(json['images']),
      verifiedPurchase: json['verified_purchase'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      reportedCount: json['reported_count'] ?? 0,
      status: json['status'] ?? 'pending',
      vendorResponse: json['vendor_response'],
      vendorResponseDate:
          json['vendor_response_date'] != null
              ? DateTime.parse(json['vendor_response_date'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'order_id': orderId,
      'rating': rating,
      'title': title,
      'content': content,
      'images': images,
      'verified_purchase': verifiedPurchase,
      'helpful_count': helpfulCount,
      'reported_count': reportedCount,
      'status': status,
      'vendor_response': vendorResponse,
      'vendor_response_date': vendorResponseDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class ReviewsSummary {
  final double averageRating;
  final int totalReviews;
  final List<int> histogram; // [1-star count, 2-star count, ..., 5-star count]

  ReviewsSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.histogram,
  });

  factory ReviewsSummary.fromJson(Map<String, dynamic> json) {
    return ReviewsSummary(
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      histogram: List<int>.from(json['histogram'] ?? [0, 0, 0, 0, 0]),
    );
  }
}
