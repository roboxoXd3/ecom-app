import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../size_chart_widget.dart';

// Enhanced color helper function with descriptive color support
Color getColorFromString(String colorName) {
  final lowerName = colorName.toLowerCase();

  // Handle descriptive color names first
  if (lowerName.contains('black') || lowerName.contains('midnight')) {
    return Colors.black;
  }
  if (lowerName.contains('white') ||
      lowerName.contains('arctic') ||
      lowerName.contains('snow')) {
    return Colors.white;
  }
  if (lowerName.contains('blue') ||
      lowerName.contains('ocean') ||
      lowerName.contains('navy')) {
    if (lowerName.contains('navy') || lowerName.contains('midnight')) {
      return const Color(0xFF000080); // Navy blue
    }
    if (lowerName.contains('ocean') || lowerName.contains('sky')) {
      return const Color(0xFF0077BE); // Ocean blue
    }
    return Colors.blue;
  }
  if (lowerName.contains('red') ||
      lowerName.contains('sunset') ||
      lowerName.contains('crimson')) {
    if (lowerName.contains('sunset')) {
      return const Color(0xFFFF4500); // Sunset red/orange
    }
    return Colors.red;
  }
  if (lowerName.contains('green') ||
      lowerName.contains('forest') ||
      lowerName.contains('emerald')) {
    return Colors.green;
  }
  if (lowerName.contains('yellow') ||
      lowerName.contains('gold') ||
      lowerName.contains('sunshine')) {
    return Colors.amber;
  }
  if (lowerName.contains('orange') || lowerName.contains('tangerine')) {
    return Colors.orange;
  }
  if (lowerName.contains('purple') ||
      lowerName.contains('violet') ||
      lowerName.contains('lavender')) {
    return Colors.purple;
  }
  if (lowerName.contains('pink') || lowerName.contains('rose')) {
    return Colors.pink;
  }
  if (lowerName.contains('brown') ||
      lowerName.contains('chocolate') ||
      lowerName.contains('coffee')) {
    return Colors.brown;
  }
  if (lowerName.contains('grey') ||
      lowerName.contains('gray') ||
      lowerName.contains('silver')) {
    return Colors.grey;
  }

  // Fallback to basic color matching
  switch (lowerName) {
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
      return Colors.grey[400]!; // Lighter grey as fallback
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
          'Color',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                product.colors.map((colorName) {
                  final isSelected =
                      enhancedController.selectedColor.value == colorName;
                  return GestureDetector(
                    onTap: () {
                      enhancedController.updateSelectedColor(colorName);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        colorName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
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
}
