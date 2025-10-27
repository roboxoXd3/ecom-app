import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../size_chart_widget.dart';

class ColorSizeSelection extends StatelessWidget {
  final Product product;

  const ColorSizeSelection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final enhancedController = Get.find<EnhancedProductController>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size Selection (if product has sizes)
          if (product.sizes.isNotEmpty) ...[
            _buildSizeSelection(enhancedController),
            const SizedBox(height: 24),
          ],

          // Color Selection (if product has colors)
          if (product.colors.isNotEmpty) ...[
            _buildColorSelection(enhancedController),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeSelection(EnhancedProductController enhancedController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Select Size',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Size Chart Button
            SizeChartButton(product: product, availableSizes: product.sizes),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                product.sizes.map((size) {
                  final isSelected =
                      enhancedController.selectedSize.value == size;
                  return ChoiceChip(
                    label: Text(
                      size,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        // Select this size
                        print('DEBUG: Size selected: "$size"');
                        enhancedController.updateSelectedSize(size);
                        print(
                          'DEBUG: EnhancedController size after update: "${enhancedController.selectedSize.value}"',
                        );
                      } else {
                        // Deselect - but we don't want to allow deselection for required sizes
                        // So we'll ignore the deselect action
                        print('DEBUG: Size deselect ignored for: "$size"');
                      }
                    },
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection(EnhancedProductController enhancedController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                product.colors.map((colorOption) {
                  final isSelected =
                      enhancedController.selectedColor.value ==
                      colorOption.name;
                  final colorValue = _parseHexColor(colorOption.hex);
                  final isLightColor = _isLightColor(colorValue);

                  return GestureDetector(
                    onTap: () {
                      enhancedController.updateSelectedColor(colorOption.name);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Color swatch
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorValue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isLightColor
                                          ? Colors.grey[300]!
                                          : Colors.transparent,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Color name
                            Text(
                              colorOption.name,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            // Show quantity badge - reactive to selected size
                            const SizedBox(width: 6),
                            Obx(() {
                              final selectedSize =
                                  enhancedController.selectedSize.value;

                              // Calculate quantity to display
                              int displayQuantity;
                              if (selectedSize.isNotEmpty &&
                                  colorOption.sizeQuantities != null) {
                                // Show size-specific quantity when size is selected
                                displayQuantity = colorOption
                                    .getQuantityForSize(selectedSize);
                              } else {
                                // Show total quantity when no size selected
                                displayQuantity = colorOption.quantity;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      displayQuantity == 0
                                          ? Colors.red[50]
                                          : displayQuantity < 5
                                          ? Colors.orange[50]
                                          : Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        displayQuantity == 0
                                            ? Colors.red[200]!
                                            : displayQuantity < 5
                                            ? Colors.orange[200]!
                                            : Colors.green[200]!,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  displayQuantity == 0
                                      ? 'Out'
                                      : 'Qty: $displayQuantity',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        displayQuantity == 0
                                            ? Colors.red[700]
                                            : displayQuantity < 5
                                            ? Colors.orange[700]
                                            : Colors.green[700],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper method to parse hex color string to Color
  Color _parseHexColor(String hexColor) {
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback color
    }
  }

  // Helper method to determine if a color is light
  bool _isLightColor(Color color) {
    // Calculate relative luminance
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }
}
