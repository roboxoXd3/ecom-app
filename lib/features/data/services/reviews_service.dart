import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/review_model.dart';

class ReviewsService {
  final _api = ApiClient.instance;

  Future<List<Review>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 20,
    String? rating,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (rating != null && rating.isNotEmpty && rating != 'all') {
        if (rating.contains('_star')) {
          params['rating'] = rating.split('_')[0];
        }
        if (rating == 'with_media') {
          params['has_media'] = 'true';
        }
      }

      final response = await _api.get(
        '/products/$productId/reviews/',
        queryParameters: params,
      );

      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      rethrow;
    }
  }

  Future<ReviewsSummary> getReviewsSummary(String productId) async {
    try {
      // Django returns summary alongside reviews in the GET /reviews/ response
      final response = await _api.get(
        '/products/$productId/reviews/',
        queryParameters: {'page_size': 1},
      );

      final data = response.data;
      if (data is Map && data['summary'] != null) {
        final s = data['summary'];
        return ReviewsSummary(
          averageRating: (s['average_rating'] ?? 0).toDouble(),
          totalReviews: s['total_reviews'] ?? 0,
          histogram: (s['histogram'] as List?)?.map((e) => e as int).toList() ??
              [0, 0, 0, 0, 0],
        );
      }

      // Fallback: try dedicated summary endpoint
      try {
        final summaryResponse = await _api.get(
          '/products/$productId/reviews-summary/',
        );
        final s = summaryResponse.data;
        return ReviewsSummary(
          averageRating: (s['average_rating'] ?? 0).toDouble(),
          totalReviews: s['total_reviews'] ?? 0,
          histogram: (s['histogram'] as List?)?.map((e) => e as int).toList() ??
              [0, 0, 0, 0, 0],
        );
      } catch (_) {
        return ReviewsSummary(
          averageRating: 0.0,
          totalReviews: 0,
          histogram: [0, 0, 0, 0, 0],
        );
      }
    } catch (e) {
      print('Error fetching reviews summary: $e');
      return ReviewsSummary(
        averageRating: 0.0,
        totalReviews: 0,
        histogram: [0, 0, 0, 0, 0],
      );
    }
  }

  Future<bool> canUserReviewProduct(String productId) async {
    if (!AuthService.isAuthenticated()) return false;

    try {
      final response = await _api.get('/products/$productId/can-review/');
      return response.data['can_review'] == true;
    } catch (e) {
      print('Error checking review eligibility: $e');
      return false;
    }
  }

  Future<String?> getUserOrderForProduct(String productId) async {
    if (!AuthService.isAuthenticated()) return null;

    try {
      final response = await _api.get('/products/$productId/can-review/');
      return response.data['order_id']?.toString();
    } catch (e) {
      print('Error getting user order for product: $e');
      return null;
    }
  }

  Future<Review> submitReview({
    required String productId,
    required int rating,
    required String title,
    required String content,
    String? orderId,
    List<String> images = const [],
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('Please sign in to submit a review');
      }

      final body = <String, dynamic>{
        'rating': rating,
        'title': title,
        'content': content,
      };
      if (orderId != null) body['order_id'] = orderId;
      if (images.isNotEmpty) body['images'] = images;

      final response = await _api.post(
        '/products/$productId/reviews/',
        data: body,
      );

      return Review.fromJson(response.data);
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _api.post('/reviews/$reviewId/helpful/');
    } catch (e) {
      print('Error marking review as helpful: $e');
      rethrow;
    }
  }

  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _api.post('/reviews/$reviewId/report/', data: {'reason': reason});
    } catch (e) {
      print('Error reporting review: $e');
      rethrow;
    }
  }

  Future<List<Review>> getReviewsWithMedia({
    required String productId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/products/$productId/reviews/',
        queryParameters: {
          'has_media': 'true',
          'page': page,
          'page_size': limit,
        },
      );

      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reviews with media: $e');
      rethrow;
    }
  }
}
