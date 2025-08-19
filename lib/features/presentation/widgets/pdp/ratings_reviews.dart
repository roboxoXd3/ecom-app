import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class RatingsReviews extends StatefulWidget {
  final Product product;

  const RatingsReviews({super.key, required this.product});

  @override
  State<RatingsReviews> createState() => _RatingsReviewsState();
}

class _RatingsReviewsState extends State<RatingsReviews> {
  String _selectedFilter = 'all';
  final List<String> _filters = [
    'all',
    'with_media',
    '5_star',
    '4_star',
    '3_star',
    '2_star',
    '1_star',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
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

          // Filter Chips
          _buildFilterChips(),

          const SizedBox(height: 16),

          // Reviews List
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final summary = widget.product.reviewsSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final totalReviews = summary.histogram.fold(0, (sum, count) => sum + count);

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
                  widget.product.rating.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.product.rating.floor()
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
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
    // Mock reviews data - in real app, this would come from API
    final mockReviews = _getMockReviews();

    return Column(
      children: [
        ...mockReviews.map((review) => _buildReviewCard(review)).toList(),

        // Load More Button
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: () {
              // Load more reviews
            },
            child: const Text('Load More Reviews'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
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
                  review['userName'][0].toUpperCase(),
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
                      review['userName'],
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
                              index < review['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppTheme.ratingStars,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (review['verified'] == true) ...[
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
          if (review['title'] != null) ...[
            Text(
              review['title'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
          ],

          // Review Text
          Text(review['text'], style: const TextStyle(fontSize: 14)),

          // Review Images (if any)
          if (review['images'] != null && review['images'].isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review['images'].length,
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
                        review['images'][index],
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
                  // Mark as helpful
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${review['helpful']})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  // Report review
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

  List<Map<String, dynamic>> _getMockReviews() {
    return [
      {
        'userName': 'Rajesh Kumar',
        'rating': 5,
        'date': '2 days ago',
        'verified': true,
        'title': 'Excellent product!',
        'text':
            'Really happy with this purchase. The quality is great and it works exactly as described. Highly recommended!',
        'helpful': 12,
        'images': [],
      },
      {
        'userName': 'Priya Sharma',
        'rating': 4,
        'date': '1 week ago',
        'verified': true,
        'title': 'Good value for money',
        'text':
            'Nice product overall. The build quality is decent and it serves the purpose well. Delivery was quick too.',
        'helpful': 8,
        'images': [],
      },
      {
        'userName': 'Amit Singh',
        'rating': 5,
        'date': '2 weeks ago',
        'verified': false,
        'title': 'Perfect!',
        'text':
            'Exactly what I was looking for. Great quality and fast delivery. Will definitely buy again.',
        'helpful': 5,
        'images': [],
      },
    ];
  }
}
