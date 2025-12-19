class ProductQA {
  final String id;
  final String productId;
  final String userId;
  final String question;
  final String? answer;
  final String? answeredBy;
  final DateTime? answeredAt;
  final int isHelpfulCount;
  final bool isVerified;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vendorResponse;
  final DateTime? vendorResponseDate;
  final String? vendorId;

  ProductQA({
    required this.id,
    required this.productId,
    required this.userId,
    required this.question,
    this.answer,
    this.answeredBy,
    this.answeredAt,
    required this.isHelpfulCount,
    required this.isVerified,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vendorResponse,
    this.vendorResponseDate,
    this.vendorId,
  });

  factory ProductQA.fromJson(Map<String, dynamic> json) {
    return ProductQA(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      question: json['question'] ?? '',
      answer: json['answer'],
      answeredBy: json['answered_by'],
      answeredAt:
          json['answered_at'] != null
              ? DateTime.parse(json['answered_at'])
              : null,
      isHelpfulCount: json['is_helpful_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      vendorResponse: json['vendor_response'],
      vendorResponseDate:
          json['vendor_response_date'] != null
              ? DateTime.parse(json['vendor_response_date'])
              : null,
      vendorId: json['vendor_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'question': question,
      'answer': answer,
      'answered_by': answeredBy,
      'answered_at': answeredAt?.toIso8601String(),
      'is_helpful_count': isHelpfulCount,
      'is_verified': isVerified,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'vendor_response': vendorResponse,
      'vendor_response_date': vendorResponseDate?.toIso8601String(),
      'vendor_id': vendorId,
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

  bool get hasAnswer {
    final ans = answer;
    return ans != null && ans.isNotEmpty;
  }

  String get displayAnswer {
    final vendorResp = vendorResponse;
    if (vendorResp != null && vendorResp.isNotEmpty) {
      return vendorResp;
    }
    return answer ?? '';
  }

  String get displayAnsweredBy {
    final vendorResp = vendorResponse;
    if (vendorResp != null && vendorResp.isNotEmpty) {
      return 'Vendor';
    }
    return answeredBy ?? 'Community';
  }

  DateTime? get displayAnsweredAt {
    if (vendorResponseDate != null) {
      return vendorResponseDate;
    }
    return answeredAt;
  }
}
