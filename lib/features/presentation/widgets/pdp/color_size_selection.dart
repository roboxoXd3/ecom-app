import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../size_chart_widget.dart';

// Color helper function
Color getColorFromString(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'grey':
    case 'gray':
      return Colors.grey;
    case 'navy':
    case 'navy blue':
      return const Color(0xFF000080);
    case 'maroon':
      return const Color(0xFF800000);
    case 'teal':
      return Colors.teal;
    case 'cyan':
      return Colors.cyan;
    case 'lime':
      return Colors.lime;
    case 'indigo':
      return Colors.indigo;
    case 'amber':
      return Colors.amber;
    default:
      return Colors.grey;
  }
}

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
          'Select Color',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                product.colors.map((colorName) {
                  // FIX: Use EnhancedProductController as single source of truth
                  final isSelected =
                      enhancedController.selectedColor.value == colorName;
                  return GestureDetector(
                    onTap: () {
                      // Update EnhancedController only (single source of truth)
                      enhancedController.updateSelectedColor(colorName);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: getColorFromString(colorName),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: _getContrastColor(
                                  getColorFromString(colorName),
                                ),
                                size: 20,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Selected color name
        Obx(
          () =>
              enhancedController.selectedColor.value.isNotEmpty
                  ? Text(
                    'Selected: ${enhancedController.selectedColor.value}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use white or black text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
