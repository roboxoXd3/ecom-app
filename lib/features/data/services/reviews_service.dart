import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get reviews for a specific product
  Future<List<Review>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 20,
    String? rating,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      print('📝 Fetching reviews for product: $productId');

      final baseQuery = _supabase
          .from('product_reviews')
          .select('*')
          .eq('product_id', productId)
          .eq('status', 'published');

      // Build query with filters
      var query = baseQuery;

      // Apply rating filter
      if (rating != null && rating.isNotEmpty && rating != 'all') {
        if (rating.contains('_star')) {
          final ratingValue = int.parse(rating.split('_')[0]);
          query = query.eq('rating', ratingValue);
        }
      }

      // Apply sorting and pagination
      final offset = (page - 1) * limit;
      final response = await query
          .order(sortBy, ascending: sortOrder == 'asc')
          .range(offset, offset + limit - 1);

      print('📝 Found ${response.length} reviews');

      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      rethrow;
    }
  }

  // Get reviews summary for a product
  Future<ReviewsSummary> getReviewsSummary(String productId) async {
    try {
      print('📊 Fetching reviews summary for product: $productId');

      // Get all reviews for the product
      final response = await _supabase
          .from('product_reviews')
          .select('rating')
          .eq('product_id', productId)
          .eq('status', 'published');

      if (response.isEmpty) {
        return ReviewsSummary(
          averageRating: 0.0,
          totalReviews: 0,
          histogram: [0, 0, 0, 0, 0],
        );
      }

      // Calculate statistics
      final ratings = response.map((r) => r['rating'] as int).toList();
      final totalReviews = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      // Build histogram [1-star, 2-star, 3-star, 4-star, 5-star]
      final histogram = List<int>.filled(5, 0);
      for (final rating in ratings) {
        if (rating >= 1 && rating <= 5) {
          histogram[rating - 1]++;
        }
      }

      print('📊 Reviews summary: $averageRating stars, $totalReviews reviews');

      return ReviewsSummary(
        averageRating: averageRating,
        totalReviews: totalReviews,
        histogram: histogram,
      );
    } catch (e) {
      print('❌ Error fetching reviews summary: $e');
      rethrow;
    }
  }

  // Check if user can review a product (has purchased and received it)
  Future<bool> canUserReviewProduct(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('order_items')
          .select('id, orders!inner(id, status, user_id)')
          .eq('product_id', productId)
          .eq('orders.user_id', userId)
          .inFilter('orders.status', ['delivered', 'completed']);

      print('🔍 Checking purchase eligibility for product: $productId');
      print('🔍 Found ${response.length} eligible orders');

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking review eligibility: $e');
      return false;
    }
  }

  // Get user's order for a specific product (for review submission)
  Future<String?> getUserOrderForProduct(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('order_items')
          .select('order_id, orders!inner(id, status, user_id)')
          .eq('product_id', productId)
          .eq('orders.user_id', userId)
          .inFilter('orders.status', ['delivered', 'completed'])
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['order_id'] as String;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user order: $e');
      return null;
    }
  }

  // Submit a new review
  Future<Review> submitReview({
    required String productId,
    required String orderId,
    required int rating,
    required String title,
    required String content,
    List<String> images = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final user = _supabase.auth.currentUser;

      print('🔐 Current user: ${user?.id}');
      print('🔐 User email: ${user?.email}');
      print('🔐 User authenticated: ${user != null}');

      if (userId == null) {
        throw Exception('Please sign in to submit a review');
      }

      // Validate that user can review this product
      final canReview = await canUserReviewProduct(productId);
      if (!canReview) {
        throw Exception(
          'You can only review products you have purchased and received',
        );
      }

      // Check if user already reviewed this product
      final existingReview =
          await _supabase
              .from('product_reviews')
              .select('id')
              .eq('product_id', productId)
              .eq('user_id', userId)
              .maybeSingle();

      if (existingReview != null) {
        throw Exception('You have already reviewed this product');
      }

      print('📝 Submitting review for product: $productId with user: $userId');

      final reviewData = {
        'product_id': productId,
        'user_id': userId,
        'order_id': orderId,
        'rating': rating,
        'title': title,
        'content': content,
        'images': images,
        'verified_purchase': true,
        'status': 'published', // Auto-approve for now
      };

      final response =
          await _supabase
              .from('product_reviews')
              .insert(reviewData)
              .select()
              .single();

      print('✅ Review submitted successfully');

      return Review.fromJson(response);
    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }

  // Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _supabase.rpc(
        'increment_review_helpful',
        params: {'review_id': reviewId},
      );

      print('👍 Marked review as helpful: $reviewId');
    } catch (e) {
      print('❌ Error marking review as helpful: $e');
      rethrow;
    }
  }

  // Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _supabase.rpc(
        'increment_review_reported',
        params: {'review_id': reviewId},
      );

      print('🚩 Reported review: $reviewId');
    } catch (e) {
      print('❌ Error reporting review: $e');
      rethrow;
    }
  }

  // Get reviews with media (photos)
  Future<List<Review>> getReviewsWithMedia({
    required String productId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📸 Fetching reviews with media for product: $productId');

      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('product_reviews')
          .select('*')
          .eq('product_id', productId)
          .eq('status', 'published')
          .not('images', 'eq', '[]')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('📸 Found ${response.length} reviews with media');

      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching reviews with media: $e');
      rethrow;
    }
  }
}
