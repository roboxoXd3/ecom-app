import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedPriceBlock extends StatelessWidget {
  final Product product;
  final VoidCallback? onCouponTap;

  const EnhancedPriceBlock({
    super.key,
    required this.product,
    this.onCouponTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title and Subtitle
          Text(
            product.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              product.subtitle!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),

          // Rating and Orders Row
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.ratingStars, size: 20),
              const SizedBox(width: 4),
              Text(
                product.rating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                ' (${product.reviews} Reviews)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (product.ordersCount != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(product.ordersCount!)} orders',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Price Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Current Price
              Text(
                '${product.currency} ${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),

              // MRP (Strike-through)
              if (product.mrp != null && product.mrp! > product.price) ...[
                Text(
                  '${product.currency} ${product.mrp!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),

                // Discount Percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_calculateDiscountPercentage()}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Tax Note
          const SizedBox(height: 8),
          Text(
            'Inclusive of all taxes',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          // Coupon Apply Section
          if (_hasCoupons()) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onCouponTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Apply coupon for extra savings',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasCoupons() {
    return product.offers.any((offer) => offer.type == 'coupon');
  }

  int _calculateDiscountPercentage() {
    if (product.mrp == null || product.mrp! <= product.price) return 0;
    return (((product.mrp! - product.price) / product.mrp!) * 100).round();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
