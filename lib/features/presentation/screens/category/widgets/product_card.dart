import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../data/models/product_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../vendor/vendor_profile_screen.dart';
import '../../../controllers/currency_controller.dart';
import '../../../controllers/product_controller.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final bool showWishlistButton;
  final bool showVendor;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    this.showWishlistButton = true,
    this.showVendor = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyController = Get.find<CurrencyController>();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getBorder(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Get.toNamed('/product-details', arguments: product.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildProductImage(context),
                    ),
                    if (showWishlistButton) _buildWishlistButton(context),
                    if (product.isOnSale) _buildSaleBadge(),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: AppTheme.getTextPrimary(context),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showVendor) _buildVendorRow(context),
                      _buildPriceRow(context, currencyController),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton(BuildContext context) {
    final productController = Get.find<ProductController>();
    return Positioned(
      top: 8,
      right: 8,
      child: Obx(() {
        final isInWishlist = productController.wishlistProductIds.contains(product.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            productController.toggleWishlist(product);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context).withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getBorder(context).withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border_rounded,
              color: isInWishlist ? Colors.red : AppTheme.getTextSecondary(context),
              size: 15,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSaleBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'SALE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildVendorRow(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sold by ',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.getTextSecondary(context),
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (product.vendor != null) {
                Get.to(() => VendorProfileScreen(vendor: product.vendor!));
              }
            },
            child: Text(
              product.vendor?.businessName ?? 'Be Smart',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, CurrencyController currencyController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 12, color: AppTheme.ratingStars),
            const SizedBox(width: 2),
            Text(
              product.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Obx(() {
            final showSale = product.isOnSale &&
                product.salePrice != null &&
                product.salePrice! < product.price;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSale) ...[
                  Flexible(
                    child: Text(
                      currencyController.getFormattedProductPrice(
                        product.price,
                        product.currency,
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    currencyController.getFormattedProductPrice(
                      showSale ? product.salePrice! : product.price,
                      product.currency,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProductImage(BuildContext context) {
    String imageUrl = '';
    if (product.primaryImage.isNotEmpty) {
      imageUrl = product.primaryImage;
    } else if (product.imageList.isNotEmpty) {
      imageUrl = product.imageList.first;
    }

    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.getBorder(context).withValues(alpha: 0.08),
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.getTextSecondary(context),
          size: 32,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: AppTheme.getBorder(context).withValues(alpha: 0.08),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.getBorder(context).withValues(alpha: 0.08),
        child: Icon(
          Icons.broken_image_outlined,
          color: AppTheme.getTextSecondary(context),
          size: 28,
        ),
      ),
    );
  }
}
