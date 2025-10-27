import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/currency_controller.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../screens/vendor/vendor_profile_screen.dart';

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
    final CurrencyController currencyController =
        Get.find<CurrencyController>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title and Subtitle
          Text(
            product.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              product.subtitle!,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Vendor Information
          if (product.vendor != null || product.vendorId.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                if (product.vendor != null) {
                  // Navigate to vendor profile screen
                  Get.to(() => VendorProfileScreen(vendor: product.vendor!));
                } else {
                  // Show message if vendor data is not available
                  SnackbarUtils.showInfo('Vendor information not available');
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 16,
                      color: AppTheme.getTextSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sold by ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        product.vendor?.businessName ??
                            'Vendor ${product.vendorId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.vendor != null &&
                        product.vendor!.averageRating > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 2),
                      Text(
                        product.vendor!.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ],
                ),
              ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              Text(
                ' (${product.reviews} Reviews)',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 14,
                ),
              ),
              if (product.ordersCount != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: AppTheme.getTextSecondary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(product.ordersCount!)} orders',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Price Section
          Obx(() {
            // Convert prices to user's preferred currency
            final convertedPrice = currencyController.convertPrice(
              product.price,
              product.currency,
            );
            final convertedMrp =
                product.mrp != null
                    ? currencyController.convertPrice(
                      product.mrp!,
                      product.currency,
                    )
                    : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Price Row - Flexible layout
                Row(
                  children: [
                    // Current Price - Takes available space
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currencyController.formatPrice(convertedPrice),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),

                    // Discount Badge - Fixed position, top-right
                    if (convertedMrp != null &&
                        convertedMrp > convertedPrice) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${((convertedMrp - convertedPrice) / convertedMrp * 100).round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // MRP Row - Separate line for better readability
                if (convertedMrp != null && convertedMrp > convertedPrice) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'M.R.P: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currencyController.formatPrice(convertedMrp),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You save ${currencyController.formatPrice(convertedMrp - convertedPrice)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }),

          // Tax Note
          const SizedBox(height: 8),
          Text(
            'Inclusive of all taxes',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextSecondary(context),
            ),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
