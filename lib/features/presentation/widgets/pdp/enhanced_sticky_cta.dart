import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

class EnhancedStickyCTA extends StatelessWidget {
  final Product product;
  final bool isVisible;

  const EnhancedStickyCTA({
    super.key,
    required this.product,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final enhancedController = Get.find<EnhancedProductController>();
    final cartController = Get.find<CartController>();
    final currencyController = Get.find<CurrencyController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 8 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            // Compact Price Display (with currency conversion)
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyController.getFormattedProductPrice(
                      product.price,
                      product.currency,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (product.mrp != null && product.mrp! > product.price)
                    Text(
                      currencyController.getFormattedProductPrice(
                        product.mrp!,
                        product.currency,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Compact Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[50],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      if (enhancedController.quantity.value > 1) {
                        enhancedController.decrementQuantity();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Obx(
                      () => Text(
                        enhancedController.quantity.value.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      enhancedController.incrementQuantity();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Compact Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _handleAddToCart(enhancedController, cartController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Compact Buy Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _handleBuyNow(enhancedController, cartController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(
    EnhancedProductController enhancedController,
    CartController cartController,
  ) async {
    // Debug: Print current state
    print('DEBUG: Product has sizes: ${product.sizes.isNotEmpty}');
    print(
      'DEBUG: EnhancedController selected size: "${enhancedController.selectedSize.value}"',
    );
    print('DEBUG: Available sizes: ${product.sizes}');

    // Use the selected size from enhanced controller
    final selectedSize = enhancedController.selectedSize.value;

    // Validate selections
    if (product.sizes.isNotEmpty && selectedSize.isEmpty) {
      SnackbarUtils.showError('Please select a size');
      return;
    }

    // Use the selected color from enhanced controller
    final selectedColor = enhancedController.selectedColor.value;

    if (product.colors.isNotEmpty && selectedColor.isEmpty) {
      SnackbarUtils.showError('Please select a color');
      return;
    }

    if (!product.inStock) {
      SnackbarUtils.showError('Product is out of stock');
      return;
    }

    try {
      await cartController.addToCart(
        product,
        selectedSize,
        selectedColor,
        enhancedController.quantity.value,
      );

      SnackbarUtils.showSuccess('Added to cart successfully');
    } catch (e) {
      SnackbarUtils.showError('Failed to add to cart');
    }
  }

  Future<void> _handleBuyNow(
    EnhancedProductController enhancedController,
    CartController cartController,
  ) async {
    // First add to cart
    await _handleAddToCart(enhancedController, cartController);

    // Then navigate to checkout
    // TODO: Navigate to checkout screen
    // Get.toNamed('/checkout');
  }
}
