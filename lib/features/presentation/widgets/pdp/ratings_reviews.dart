import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../controllers/reviews_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

class RatingsReviews extends StatefulWidget {
  final Product product;

  const RatingsReviews({super.key, required this.product});

  @override
  State<RatingsReviews> createState() => _RatingsReviewsState();
}

class _RatingsReviewsState extends State<RatingsReviews> {
  final ReviewsController reviewsController = Get.put(ReviewsController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load reviews when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewsController.loadReviews(widget.product.id);
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      reviewsController.loadMoreReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (reviewsController.isLoading.value &&
            reviewsController.reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (reviewsController.error.value.isNotEmpty &&
            reviewsController.reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load reviews',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed:
                        () => reviewsController.loadReviews(
                          widget.product.id,
                          refresh: true,
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ratings & Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Rating Summary
            _buildRatingSummary(),

            const SizedBox(height: 16),

            // Write Review Section
            _buildWriteReviewSection(),

            const SizedBox(height: 16),

            // Filter Chips
            _buildFilterChips(),

            const SizedBox(height: 16),

            // Reviews List
            _buildReviewsList(),
          ],
        );
      }),
    );
  }

  Widget _buildRatingSummary() {
    final summary = reviewsController.reviewsSummary.value;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final totalReviews = summary.totalReviews;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Overall Rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < summary.averageRating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: AppTheme.ratingStars,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews Reviews',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Rating Histogram
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final starCount = 5 - index;
                final count =
                    index < summary.histogram.length
                        ? summary.histogram[summary.histogram.length -
                            1 -
                            index]
                        : 0;
                final percentage =
                    totalReviews > 0 ? (count / totalReviews) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$starCount', style: const TextStyle(fontSize: 12)),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: AppTheme.ratingStars,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.ratingStars,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'all',
      'with_media',
      '5_star',
      '4_star',
      '3_star',
      '2_star',
      '1_star',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = reviewsController.selectedFilter.value == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                reviewsController.applyFilter(filter);
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Reviews';
      case 'with_media':
        return 'With Photos';
      case '5_star':
        return '5 Star';
      case '4_star':
        return '4 Star';
      case '3_star':
        return '3 Star';
      case '2_star':
        return '2 Star';
      case '1_star':
        return '1 Star';
      default:
        return filter;
    }
  }

  Widget _buildReviewsList() {
    if (reviewsController.reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Be the first to review this product!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...reviewsController.reviews
            .map((review) => _buildReviewCard(review))
            .toList(),

        // Load More Button
        if (reviewsController.hasMoreReviews.value) ...[
          const SizedBox(height: 16),
          Center(
            child:
                reviewsController.isLoadingMore.value
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                      onPressed: reviewsController.loadMoreReviews,
                      child: const Text('Load More Reviews'),
                    ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info and Rating
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  'U', // We don't have user name in the model, so use generic
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User', // Generic user name since we don't store it
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppTheme.ratingStars,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (review.verifiedPurchase) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review Title
          if (review.title.isNotEmpty) ...[
            Text(
              review.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
          ],

          // Review Text
          Text(review.content, style: const TextStyle(fontSize: 14)),

          // Review Images (if any)
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, color: Colors.grey);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Helpful Actions
          Row(
            children: [
              InkWell(
                onTap: () {
                  reviewsController.markReviewHelpful(review.id);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${review.helpfulCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  _showReportDialog(review.id);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 16),
                    SizedBox(width: 4),
                    Text('Report', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String reviewId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Review'),
            content: const Text('Why are you reporting this review?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  reviewsController.reportReview(
                    reviewId,
                    'Inappropriate content',
                  );
                },
                child: const Text('Report'),
              ),
            ],
          ),
    );
  }

  Widget _buildWriteReviewSection() {
    return Obx(() {
      final currentUser = Supabase.instance.client.auth.currentUser;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Write a Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (currentUser == null) ...[
              // Not logged in
              Text(
                'Please sign in to write a review',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text('Sign In'),
              ),
            ] else if (!reviewsController.canUserReview.value) ...[
              // Cannot review (hasn't purchased)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Verified Purchase Required',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only customers who have purchased and received this product can write reviews.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to product purchase or show more info
                      SnackbarUtils.showInfo(
                        'Purchase this product to write a review',
                      );
                    },
                    child: const Text('Purchase Product'),
                  ),
                ],
              ),
            ] else ...[
              // Can review
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Verified Purchase',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can write a review for this product.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showWriteReviewDialog(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Write Review'),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  void _showWriteReviewDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Write Your Review'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating Selection
                        const Text(
                          'Rating *',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => selectedRating = index + 1,
                                  ),
                              child: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppTheme.ratingStars,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Review Title *',
                            hintText: 'Summarize your experience',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 100,
                        ),
                        const SizedBox(height: 16),

                        // Content
                        TextField(
                          controller: contentController,
                          decoration: const InputDecoration(
                            labelText: 'Your Review *',
                            hintText:
                                'Share your thoughts about this product...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                          maxLength: 1000,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Obx(
                      () => ElevatedButton(
                        onPressed:
                            reviewsController.isLoading.value
                                ? null
                                : () async {
                                  final title = titleController.text.trim();
                                  final content = contentController.text.trim();

                                  if (title.isEmpty) {
                                    SnackbarUtils.showWarning(
                                      'Please enter a review title',
                                    );
                                    return;
                                  }

                                  if (content.isEmpty) {
                                    SnackbarUtils.showWarning(
                                      'Please enter your review',
                                    );
                                    return;
                                  }

                                  if (content.length < 10) {
                                    SnackbarUtils.showWarning(
                                      'Review must be at least 10 characters long',
                                    );
                                    return;
                                  }

                                  final success = await reviewsController
                                      .submitReview(
                                        productId: widget.product.id,
                                        rating: selectedRating,
                                        title: title,
                                        content: content,
                                      );

                                  if (success) {
                                    Navigator.pop(context);
                                    SnackbarUtils.showSuccess(
                                      'Review submitted successfully!',
                                    );
                                  }
                                },
                        child:
                            reviewsController.isLoading.value
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Submit Review'),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
