import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/currency_controller.dart';

class RecommendationShelves extends StatelessWidget {
  final ProductRecommendations? recommendations;
  final Function(String productId)? onProductTap;

  const RecommendationShelves({
    super.key,
    this.recommendations,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Similar Products Carousel
        if (recommendations!.similar.isNotEmpty)
          _buildProductCarousel(
            'Similar Products',
            recommendations!.similar,
            context,
          ),

        // More from Seller Carousel
        if (recommendations!.fromSeller.isNotEmpty)
          _buildProductCarousel(
            'More from this Seller',
            recommendations!.fromSeller,
            context,
          ),

        // You Might Also Like Grid
        if (recommendations!.youMightAlsoLike.isNotEmpty)
          _buildProductGrid(
            'You Might Also Like',
            recommendations!.youMightAlsoLike,
            context,
          ),
      ],
    );
  }

  Widget _buildProductCarousel(
    String title,
    List<String> productIds,
    BuildContext context,
  ) {
    final mockProducts = _getMockProducts(productIds);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to see all products
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mockProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(mockProducts[index], context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    String title,
    List<String> productIds,
    BuildContext context,
  ) {
    final mockProducts = _getMockProducts(productIds);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to see all products
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: mockProducts.length > 4 ? 4 : mockProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(
                mockProducts[index],
                context,
                isGrid: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    BuildContext context, {
    bool isGrid = false,
  }) {
    return Container(
      width: isGrid ? null : 160,
      margin: isGrid ? null : const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (onProductTap != null) {
            onProductTap!(product['id']);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: isGrid ? 3 : 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product['image'],
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                  ),
                ),
              ),
            ),

            // Product Info
            Expanded(
              flex: isGrid ? 2 : 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.ratingStars,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product['reviews']})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Price (with currency conversion)
                    GetBuilder<CurrencyController>(
                      builder:
                          (currencyController) => Row(
                            children: [
                              Text(
                                currencyController.getFormattedProductPrice(
                                  product['price'],
                                  product['currency'] ?? 'USD',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (product['mrp'] != null &&
                                  product['mrp'] > product['price']) ...[
                                const SizedBox(width: 6),
                                Text(
                                  currencyController.getFormattedProductPrice(
                                    product['mrp'],
                                    product['currency'] ?? 'USD',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                    ),

                    const SizedBox(height: 4),

                    // Quick Add Button (for simple products)
                    if (!isGrid)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Quick add to cart
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          child: Text(
                            'Quick Add',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMockProducts(List<String> productIds) {
    // Mock product data - in real app, this would come from API
    return [
      {
        'id': 'prod_1',
        'name': 'Digital Kitchen Scale',
        'image':
            'https://via.placeholder.com/200x200/E0E0E0/808080?text=Kitchen+Scale',
        'price': 899,
        'mrp': 1299,
        'rating': 4.2,
        'reviews': 156,
      },
      {
        'id': 'prod_2',
        'name': 'Smart Body Analyzer',
        'image':
            'https://via.placeholder.com/200x200/E0E0E0/808080?text=Body+Analyzer',
        'price': 2499,
        'mrp': 3999,
        'rating': 4.5,
        'reviews': 89,
      },
      {
        'id': 'prod_3',
        'name': 'Precision Weight Scale',
        'image':
            'https://via.placeholder.com/200x200/E0E0E0/808080?text=Precision+Scale',
        'price': 1299,
        'mrp': 1899,
        'rating': 4.3,
        'reviews': 234,
      },
      {
        'id': 'prod_4',
        'name': 'Bluetooth Smart Scale',
        'image':
            'https://via.placeholder.com/200x200/E0E0E0/808080?text=Smart+Scale',
        'price': 3499,
        'mrp': 4999,
        'rating': 4.6,
        'reviews': 67,
      },
      {
        'id': 'prod_5',
        'name': 'Portable Travel Scale',
        'image':
            'https://via.placeholder.com/200x200/E0E0E0/808080?text=Travel+Scale',
        'price': 599,
        'mrp': 899,
        'rating': 4.1,
        'reviews': 123,
      },
    ];
  }
}
