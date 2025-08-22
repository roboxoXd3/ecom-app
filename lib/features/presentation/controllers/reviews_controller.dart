import 'package:get/get.dart';
import '../../data/models/review_model.dart';
import '../../data/services/reviews_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class ReviewsController extends GetxController {
  final ReviewsService _reviewsService = ReviewsService();

  // Observable state
  final RxList<Review> reviews = <Review>[].obs;
  final Rx<ReviewsSummary?> reviewsSummary = Rx<ReviewsSummary?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString sortBy = 'created_at'.obs;
  final RxString sortOrder = 'desc'.obs;
  final RxBool canUserReview = false.obs;
  final RxString userOrderId = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreReviews = true.obs;

  // Current product ID
  String? _currentProductId;

  // Check if user can review this product
  Future<void> checkReviewEligibility(String productId) async {
    try {
      canUserReview.value = await _reviewsService.canUserReviewProduct(
        productId,
      );
      if (canUserReview.value) {
        userOrderId.value =
            await _reviewsService.getUserOrderForProduct(productId) ?? '';
      }
      print('🔍 User can review product $productId: ${canUserReview.value}');
    } catch (e) {
      print('❌ Error checking review eligibility: $e');
      canUserReview.value = false;
      userOrderId.value = '';
    }
  }

  // Load reviews for a product
  Future<void> loadReviews(String productId, {bool refresh = false}) async {
    try {
      if (refresh || _currentProductId != productId) {
        _currentProductId = productId;
        currentPage.value = 1;
        hasMoreReviews.value = true;
        reviews.clear();
      }

      if (!hasMoreReviews.value && !refresh) return;

      isLoading.value = refresh || reviews.isEmpty;
      isLoadingMore.value = !refresh && reviews.isNotEmpty;
      error.value = '';

      print(
        '📝 Loading reviews for product: $productId, page: ${currentPage.value}',
      );

      // Load reviews and summary in parallel
      final futures = [
        _reviewsService.getProductReviews(
          productId: productId,
          page: currentPage.value,
          rating: selectedFilter.value,
          sortBy: sortBy.value,
          sortOrder: sortOrder.value,
        ),
        if (refresh || reviewsSummary.value == null)
          _reviewsService.getReviewsSummary(productId),
      ];

      final results = await Future.wait(futures);
      final newReviews = results[0] as List<Review>;

      if (results.length > 1) {
        reviewsSummary.value = results[1] as ReviewsSummary;
      }

      if (refresh) {
        reviews.value = newReviews;
      } else {
        reviews.addAll(newReviews);
      }

      // Check if there are more reviews to load
      hasMoreReviews.value = newReviews.length >= 20;

      if (hasMoreReviews.value) {
        currentPage.value++;
      }

      // Check if user can review this product
      await checkReviewEligibility(productId);

      print('✅ Loaded ${newReviews.length} reviews, total: ${reviews.length}');
    } catch (e) {
      error.value = 'Failed to load reviews: $e';
      print('❌ Error loading reviews: $e');

      if (reviews.isEmpty) {
        SnackbarUtils.showError('Failed to load reviews');
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Load more reviews (pagination)
  Future<void> loadMoreReviews() async {
    if (_currentProductId != null &&
        hasMoreReviews.value &&
        !isLoadingMore.value) {
      await loadReviews(_currentProductId!, refresh: false);
    }
  }

  // Apply filter and reload reviews
  Future<void> applyFilter(String filter) async {
    if (selectedFilter.value != filter && _currentProductId != null) {
      selectedFilter.value = filter;
      await loadReviews(_currentProductId!, refresh: true);
    }
  }

  // Change sorting and reload reviews
  Future<void> changeSorting(String newSortBy, String newSortOrder) async {
    if ((sortBy.value != newSortBy || sortOrder.value != newSortOrder) &&
        _currentProductId != null) {
      sortBy.value = newSortBy;
      sortOrder.value = newSortOrder;
      await loadReviews(_currentProductId!, refresh: true);
    }
  }

  // Submit a new review
  Future<bool> submitReview({
    required String productId,
    String? orderId,
    required int rating,
    required String title,
    required String content,
    List<String> images = const [],
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('📝 Submitting review for product: $productId');

      // Use provided orderId or the stored userOrderId
      final finalOrderId = orderId ?? userOrderId.value;
      if (finalOrderId.isEmpty) {
        throw Exception('No valid order found for this product');
      }

      final newReview = await _reviewsService.submitReview(
        productId: productId,
        orderId: finalOrderId,
        rating: rating,
        title: title,
        content: content,
        images: images,
      );

      // Add the new review to the top of the list
      reviews.insert(0, newReview);

      // Reload summary to update statistics
      reviewsSummary.value = await _reviewsService.getReviewsSummary(productId);

      SnackbarUtils.showSuccess('Review submitted successfully!');
      print('✅ Review submitted successfully');

      return true;
    } catch (e) {
      error.value = 'Failed to submit review: $e';
      print('❌ Error submitting review: $e');
      SnackbarUtils.showError('Failed to submit review');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _reviewsService.markReviewHelpful(reviewId);

      // Update the local review
      final reviewIndex = reviews.indexWhere((r) => r.id == reviewId);
      if (reviewIndex != -1) {
        final updatedReview = Review.fromJson({
          ...reviews[reviewIndex].toJson(),
          'helpful_count': reviews[reviewIndex].helpfulCount + 1,
        });
        reviews[reviewIndex] = updatedReview;
      }

      SnackbarUtils.showSuccess('Marked as helpful');
    } catch (e) {
      print('❌ Error marking review as helpful: $e');
      SnackbarUtils.showError('Failed to mark as helpful');
    }
  }

  // Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _reviewsService.reportReview(reviewId, reason);
      SnackbarUtils.showSuccess('Review reported');
    } catch (e) {
      print('❌ Error reporting review: $e');
      SnackbarUtils.showError('Failed to report review');
    }
  }

  // Get reviews with media
  Future<void> loadReviewsWithMedia(String productId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final mediaReviews = await _reviewsService.getReviewsWithMedia(
        productId: productId,
      );

      reviews.value = mediaReviews;
      print('📸 Loaded ${mediaReviews.length} reviews with media');
    } catch (e) {
      error.value = 'Failed to load reviews with media: $e';
      print('❌ Error loading reviews with media: $e');
      SnackbarUtils.showError('Failed to load reviews with media');
    } finally {
      isLoading.value = false;
    }
  }

  // Get filtered reviews count
  int get filteredReviewsCount {
    if (selectedFilter.value == 'all') {
      return reviewsSummary.value?.totalReviews ?? 0;
    } else if (selectedFilter.value == 'with_media') {
      return reviews.where((r) => r.images.isNotEmpty).length;
    } else if (selectedFilter.value.contains('_star')) {
      final rating = int.parse(selectedFilter.value.split('_')[0]);
      final summary = reviewsSummary.value;
      if (summary != null && rating >= 1 && rating <= 5) {
        return summary.histogram[rating - 1];
      }
    }
    return 0;
  }

  // Reset controller state
  void reset() {
    reviews.clear();
    reviewsSummary.value = null;
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = '';
    selectedFilter.value = 'all';
    sortBy.value = 'created_at';
    sortOrder.value = 'desc';
    currentPage.value = 1;
    hasMoreReviews.value = true;
    _currentProductId = null;
  }
}
