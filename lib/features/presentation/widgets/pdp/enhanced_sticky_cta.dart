import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

// Design style options for the CTA section
enum CTADesignStyle {
  classicTwoRow, // Option 1: Clean two-row layout (Recommended)
  cardElevated, // Option 2: Elevated card with shadow
  accentBorder, // Option 3: Left border with brand accent
  gradientPremium, // Option 4: Gradient background
  compactSegmented, // Option 5: Segmented control style
}

// CONFIGURATION: Change this to switch between design styles
const CTADesignStyle selectedDesign = CTADesignStyle.classicTwoRow;

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

    return _buildSelectedDesign(
      context,
      enhancedController,
      cartController,
      currencyController,
    );
  }

  Widget _buildSelectedDesign(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    switch (selectedDesign) {
      case CTADesignStyle.classicTwoRow:
        return _buildClassicTwoRow(
          context,
          enhancedController,
          cartController,
          currencyController,
        );
      case CTADesignStyle.cardElevated:
        return _buildCardElevated(
          context,
          enhancedController,
          cartController,
          currencyController,
        );
      case CTADesignStyle.accentBorder:
        return _buildAccentBorder(
          context,
          enhancedController,
          cartController,
          currencyController,
        );
      case CTADesignStyle.gradientPremium:
        return _buildGradientPremium(
          context,
          enhancedController,
          cartController,
          currencyController,
        );
      case CTADesignStyle.compactSegmented:
        return _buildCompactSegmented(
          context,
          enhancedController,
          cartController,
          currencyController,
        );
    }
  }

  // ============================================================================
  // DESIGN OPTION 1: Classic Two-Row Minimal (Recommended)
  // ============================================================================
  Widget _buildClassicTwoRow(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Price + Quantity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Section (stacked vertically)
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current Price
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyController.getFormattedProductPrice(
                                product.price,
                                product.currency,
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                height: 1.2,
                              ),
                            ),
                          ),
                          // MRP (if available)
                          if (product.mrp != null &&
                              product.mrp! > product.price)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyController.getFormattedProductPrice(
                                    product.mrp!,
                                    product.currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(context),
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Quantity Selector (compact)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.getBorder(context),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.getSurface(context),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityButton(context, Icons.remove, () {
                          if (enhancedController.quantity.value > 1) {
                            enhancedController.decrementQuantity();
                          }
                        }, enhancedController),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: const BoxConstraints(minWidth: 40),
                          child: Obx(
                            () => Text(
                              enhancedController.quantity.value.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextPrimary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          context,
                          Icons.add,
                          () => enhancedController.incrementQuantity(),
                          enhancedController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Subtle divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 1,
                  color: AppTheme.getBorder(context).withOpacity(0.3),
                ),
              ),

              // Row 2: Action Buttons (Equal width)
              Obx(() {
                final isAvailable = _checkAvailability(enhancedController);

                return Row(
                  children: [
                    // Add to Cart Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleAddToCart(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? AppTheme.primaryColor : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAvailable ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Buy Now Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleBuyNow(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? Colors.orange[600] : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAvailable ? 'Buy Now' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESIGN OPTION 2: Card-Style Elevated CTA
  // ============================================================================
  Widget _buildCardElevated(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.getBackground(context)),
      child: SafeArea(
        top: false,
        child: Card(
          elevation: 6,
          shadowColor: AppTheme.primaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Price + Quantity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currencyController.getFormattedProductPrice(
                                  product.price,
                                  product.currency,
                                ),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (product.mrp != null &&
                                product.mrp! > product.price)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    currencyController.getFormattedProductPrice(
                                      product.mrp!,
                                      product.currency,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.getTextSecondary(context),
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildCompactQuantitySelector(context, enhancedController),
                  ],
                ),

                const SizedBox(height: 16),

                // Row 2: Buttons
                Obx(() {
                  final isAvailable = _checkAvailability(enhancedController);
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isAvailable
                                  ? () => _handleAddToCart(
                                    enhancedController,
                                    cartController,
                                  )
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isAvailable
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            isAvailable ? 'Add to Cart' : 'Out of Stock',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isAvailable
                                  ? () => _handleBuyNow(
                                    enhancedController,
                                    cartController,
                                  )
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isAvailable ? Colors.orange[600] : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            isAvailable ? 'Buy Now' : 'Out of Stock',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESIGN OPTION 3: Accent-Border Emphasis
  // ============================================================================
  Widget _buildAccentBorder(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        border: Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 4),
          top: BorderSide(
            color: AppTheme.getBorder(context).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          color: AppTheme.primaryColor.withOpacity(0.03),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Price + Quantity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyController.getFormattedProductPrice(
                                product.price,
                                product.currency,
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (product.mrp != null &&
                              product.mrp! > product.price)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyController.getFormattedProductPrice(
                                    product.mrp!,
                                    product.currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(context),
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildCompactQuantitySelector(context, enhancedController),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2: Outlined Buttons
              Obx(() {
                final isAvailable = _checkAvailability(enhancedController);
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleAddToCart(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isAvailable ? AppTheme.primaryColor : Colors.grey,
                          side: BorderSide(
                            color:
                                isAvailable
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isAvailable ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleBuyNow(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? Colors.orange[600] : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAvailable ? 'Buy Now' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESIGN OPTION 4: Gradient Background Premium
  // ============================================================================
  Widget _buildGradientPremium(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [
                    AppTheme.getSurface(context),
                    AppTheme.primaryColor.withOpacity(0.08),
                  ]
                  : [
                    AppTheme.getSurface(context),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Price + Quantity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currencyController.getFormattedProductPrice(
                                product.price,
                                product.currency,
                              ),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (product.mrp != null &&
                              product.mrp! > product.price)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currencyController.getFormattedProductPrice(
                                    product.mrp!,
                                    product.currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextSecondary(context),
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildCompactQuantitySelector(context, enhancedController),
                ],
              ),

              const SizedBox(height: 14),

              // Row 2: Solid Buttons with Elevation
              Obx(() {
                final isAvailable = _checkAvailability(enhancedController);
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleAddToCart(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? AppTheme.primaryColor : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          isAvailable ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isAvailable
                                ? () => _handleBuyNow(
                                  enhancedController,
                                  cartController,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAvailable ? Colors.orange[600] : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          isAvailable ? 'Buy Now' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DESIGN OPTION 5: Compact Segmented Control Style
  // ============================================================================
  Widget _buildCompactSegmented(
    BuildContext context,
    EnhancedProductController enhancedController,
    CartController cartController,
    CurrencyController currencyController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Horizontal Price + Quantity
              Row(
                children: [
                  // Price (horizontal layout)
                  Expanded(
                    child: Obx(
                      () => Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currencyController.getFormattedProductPrice(
                                  product.price,
                                  product.currency,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (product.mrp != null &&
                              product.mrp! > product.price)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyController.getFormattedProductPrice(
                                      product.mrp!,
                                      product.currency,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.getTextSecondary(context),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Compact Quantity
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.getBorder(context),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
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
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              enhancedController.quantity.value.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => enhancedController.incrementQuantity(),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 2: Segmented Control Buttons
              Obx(() {
                final isAvailable = _checkAvailability(enhancedController);
                return Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isAvailable
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Add to Cart (60% width)
                      Expanded(
                        flex: 6,
                        child: Material(
                          color:
                              isAvailable
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: InkWell(
                            onTap:
                                isAvailable
                                    ? () => _handleAddToCart(
                                      enhancedController,
                                      cartController,
                                    )
                                    : null,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isAvailable ? 'Add to Cart' : 'Out of Stock',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      Container(
                        width: 2,
                        color:
                            isAvailable
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                      ),

                      // Buy Now (40% width)
                      Expanded(
                        flex: 4,
                        child: Material(
                          color:
                              isAvailable
                                  ? Colors.orange[600]
                                  : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: InkWell(
                            onTap:
                                isAvailable
                                    ? () => _handleBuyNow(
                                      enhancedController,
                                      cartController,
                                    )
                                    : null,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                isAvailable ? 'Buy Now' : 'Unavailable',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Helper Widgets & Methods
  // ============================================================================

  Widget _buildQuantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
    EnhancedProductController controller,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Icon(icon, size: 18, color: AppTheme.getTextPrimary(context)),
      ),
    );
  }

  Widget _buildCompactQuantitySelector(
    BuildContext context,
    EnhancedProductController enhancedController,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.getBorder(context), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.getSurface(context),
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 18,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            constraints: const BoxConstraints(minWidth: 36),
            child: Obx(
              () => Text(
                enhancedController.quantity.value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          InkWell(
            onTap: () => enhancedController.incrementQuantity(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                size: 18,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _checkAvailability(EnhancedProductController enhancedController) {
    final selectedColor = enhancedController.selectedColor.value;
    final selectedSize = enhancedController.selectedSize.value;

    bool isAvailable = product.inStock;

    if (product.colors.isNotEmpty && selectedColor.isNotEmpty) {
      final colorOption = product.colors.firstWhere(
        (c) => c.name == selectedColor,
        orElse: () => ColorOption(name: '', hex: '', quantity: 0),
      );

      if (product.sizes.isNotEmpty && selectedSize.isNotEmpty) {
        isAvailable = colorOption.isSizeAvailable(selectedSize);
      } else {
        isAvailable = colorOption.quantity > 0;
      }
    }

    return isAvailable;
  }

  Future<void> _handleAddToCart(
    EnhancedProductController enhancedController,
    CartController cartController,
  ) async {
    final selectedSize = enhancedController.selectedSize.value;
    final selectedColor = enhancedController.selectedColor.value;

    // Validate selections
    if (product.sizes.isNotEmpty && selectedSize.isEmpty) {
      SnackbarUtils.showError('Please select a size');
      return;
    }

    if (product.colors.isNotEmpty && selectedColor.isEmpty) {
      SnackbarUtils.showError('Please select a color');
      return;
    }

    // Check stock availability
    if (product.colors.isNotEmpty) {
      final colorOption = product.colors.firstWhere(
        (c) => c.name == selectedColor,
        orElse: () => ColorOption(name: '', hex: '', quantity: 0),
      );

      if (product.sizes.isNotEmpty && selectedSize.isNotEmpty) {
        if (!colorOption.isSizeAvailable(selectedSize)) {
          SnackbarUtils.showError(
            '$selectedColor in size $selectedSize is out of stock',
          );
          return;
        }
      } else if (colorOption.quantity == 0) {
        SnackbarUtils.showError('$selectedColor is out of stock');
        return;
      }
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
    // Get.toNamed('/checkout');
  }
}
