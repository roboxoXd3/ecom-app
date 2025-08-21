import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/size_chart_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/size_chart_repository.dart';
import '../../../core/theme/app_theme.dart';

// Import for legacy size chart fallback
class SizeChartData {
  static Map<String, SizeChartModel> getSizeCharts() {
    return {
      'mens_clothing': SizeChartModel(
        id: 'legacy_mens',
        name: 'Men\'s Clothing Standard',
        category: 'Men\'s Clothing',
        subcategory: 'Standard',
        measurementTypes: ['Chest', 'Waist', 'Length'],
        measurementInstructions: 'Measure while wearing light clothing.',
        sizeRecommendations: {
          'S': 'Small (34-36 chest)',
          'M': 'Medium (38-40 chest)',
          'L': 'Large (42-44 chest)',
          'XL': 'Extra Large (46-48 chest)',
        },
        entries: [
          SizeChartEntry(
            size: 'S',
            measurements: {
              'Chest': SizeMeasurement(cm: 86, inches: 34),
              'Waist': SizeMeasurement(cm: 76, inches: 30),
              'Length': SizeMeasurement(cm: 68, inches: 27),
            },
            sortOrder: 0,
          ),
          SizeChartEntry(
            size: 'M',
            measurements: {
              'Chest': SizeMeasurement(cm: 91, inches: 36),
              'Waist': SizeMeasurement(cm: 81, inches: 32),
              'Length': SizeMeasurement(cm: 70, inches: 28),
            },
            sortOrder: 1,
          ),
          SizeChartEntry(
            size: 'L',
            measurements: {
              'Chest': SizeMeasurement(cm: 96, inches: 38),
              'Waist': SizeMeasurement(cm: 86, inches: 34),
              'Length': SizeMeasurement(cm: 72, inches: 29),
            },
            sortOrder: 2,
          ),
          SizeChartEntry(
            size: 'XL',
            measurements: {
              'Chest': SizeMeasurement(cm: 101, inches: 40),
              'Waist': SizeMeasurement(cm: 91, inches: 36),
              'Length': SizeMeasurement(cm: 74, inches: 30),
            },
            sortOrder: 3,
          ),
        ],
      ),
      'womens_clothing': SizeChartModel(
        id: 'legacy_womens',
        name: 'Women\'s Clothing Standard',
        category: 'Women\'s Clothing',
        subcategory: 'Standard',
        measurementTypes: ['Bust', 'Waist', 'Hips', 'Length'],
        measurementInstructions: 'Measure while wearing light clothing.',
        sizeRecommendations: {
          'XS': 'Extra Small (32 bust)',
          'S': 'Small (34 bust)',
          'M': 'Medium (36 bust)',
          'L': 'Large (38 bust)',
          'XL': 'Extra Large (40 bust)',
        },
        entries: [
          SizeChartEntry(
            size: 'XS',
            measurements: {
              'Bust': SizeMeasurement(cm: 81, inches: 32),
              'Waist': SizeMeasurement(cm: 66, inches: 26),
              'Hips': SizeMeasurement(cm: 86, inches: 34),
              'Length': SizeMeasurement(cm: 66, inches: 26),
            },
            sortOrder: 0,
          ),
          SizeChartEntry(
            size: 'S',
            measurements: {
              'Bust': SizeMeasurement(cm: 86, inches: 34),
              'Waist': SizeMeasurement(cm: 71, inches: 28),
              'Hips': SizeMeasurement(cm: 91, inches: 36),
              'Length': SizeMeasurement(cm: 68, inches: 27),
            },
            sortOrder: 1,
          ),
          SizeChartEntry(
            size: 'M',
            measurements: {
              'Bust': SizeMeasurement(cm: 91, inches: 36),
              'Waist': SizeMeasurement(cm: 76, inches: 30),
              'Hips': SizeMeasurement(cm: 96, inches: 38),
              'Length': SizeMeasurement(cm: 70, inches: 28),
            },
            sortOrder: 2,
          ),
          SizeChartEntry(
            size: 'L',
            measurements: {
              'Bust': SizeMeasurement(cm: 96, inches: 38),
              'Waist': SizeMeasurement(cm: 81, inches: 32),
              'Hips': SizeMeasurement(cm: 101, inches: 40),
              'Length': SizeMeasurement(cm: 72, inches: 29),
            },
            sortOrder: 3,
          ),
          SizeChartEntry(
            size: 'XL',
            measurements: {
              'Bust': SizeMeasurement(cm: 101, inches: 40),
              'Waist': SizeMeasurement(cm: 86, inches: 34),
              'Hips': SizeMeasurement(cm: 106, inches: 42),
              'Length': SizeMeasurement(cm: 74, inches: 30),
            },
            sortOrder: 4,
          ),
        ],
      ),
      'footwear': SizeChartModel(
        id: 'legacy_footwear',
        name: 'Footwear Size Chart',
        category: 'Sports',
        subcategory: 'Athletic Footwear',
        measurementTypes: ['Foot Length', 'Foot Width'],
        measurementInstructions:
            'Measure your foot from heel to longest toe. For width, measure the widest part of your foot. It\'s best to measure in the evening when your feet are slightly swollen. Wear the type of socks you plan to wear with the shoes.',
        sizeRecommendations: {
          '7': 'US 7 - Foot length: 9.5-9.75 inches (24.1-24.8 cm)',
          '8': 'US 8 - Foot length: 9.75-10 inches (24.8-25.4 cm)',
          '9': 'US 9 - Foot length: 10-10.25 inches (25.4-26 cm)',
          '10': 'US 10 - Foot length: 10.25-10.5 inches (26-26.7 cm)',
          '11': 'US 11 - Foot length: 10.5-10.75 inches (26.7-27.3 cm)',
        },
        entries: [
          SizeChartEntry(
            size: '7',
            measurements: {
              'Foot Length': SizeMeasurement(cm: 24.5, inches: 9.6),
              'Foot Width': SizeMeasurement(cm: 9.5, inches: 3.7),
            },
            sortOrder: 0,
          ),
          SizeChartEntry(
            size: '8',
            measurements: {
              'Foot Length': SizeMeasurement(cm: 25.1, inches: 9.9),
              'Foot Width': SizeMeasurement(cm: 9.7, inches: 3.8),
            },
            sortOrder: 1,
          ),
          SizeChartEntry(
            size: '9',
            measurements: {
              'Foot Length': SizeMeasurement(cm: 25.7, inches: 10.1),
              'Foot Width': SizeMeasurement(cm: 9.9, inches: 3.9),
            },
            sortOrder: 2,
          ),
          SizeChartEntry(
            size: '10',
            measurements: {
              'Foot Length': SizeMeasurement(cm: 26.4, inches: 10.4),
              'Foot Width': SizeMeasurement(cm: 10.1, inches: 4.0),
            },
            sortOrder: 3,
          ),
          SizeChartEntry(
            size: '11',
            measurements: {
              'Foot Length': SizeMeasurement(cm: 27.0, inches: 10.6),
              'Foot Width': SizeMeasurement(cm: 10.3, inches: 4.1),
            },
            sortOrder: 4,
          ),
        ],
      ),
      'accessories': SizeChartModel(
        id: 'legacy_accessories',
        name: 'Accessories Size Chart',
        category: 'Accessories',
        subcategory: 'Jewelry & Wearable Accessories',
        measurementTypes: ['Circumference', 'Diameter'],
        measurementInstructions:
            'For rings: measure the inside diameter of a well-fitting ring. For bracelets: measure your wrist circumference with a measuring tape where you want to wear the bracelet.',
        sizeRecommendations: {
          'S': 'Small - 6-7 inch wrist / Size 6-7 ring',
          'M': 'Medium - 7-8 inch wrist / Size 8-9 ring',
          'L': 'Large - 8-9 inch wrist / Size 10-11 ring',
        },
        entries: [
          SizeChartEntry(
            size: 'S',
            measurements: {
              'Circumference': SizeMeasurement(cm: 16.5, inches: 6.5),
              'Diameter': SizeMeasurement(cm: 1.6, inches: 0.6),
            },
            sortOrder: 0,
          ),
          SizeChartEntry(
            size: 'M',
            measurements: {
              'Circumference': SizeMeasurement(cm: 19.0, inches: 7.5),
              'Diameter': SizeMeasurement(cm: 1.8, inches: 0.7),
            },
            sortOrder: 1,
          ),
          SizeChartEntry(
            size: 'L',
            measurements: {
              'Circumference': SizeMeasurement(cm: 21.5, inches: 8.5),
              'Diameter': SizeMeasurement(cm: 2.0, inches: 0.8),
            },
            sortOrder: 2,
          ),
        ],
      ),
    };
  }
}

class SizeChartController extends GetxController {
  var isInches = false.obs;
  var selectedSize = ''.obs;
  var isLoading = false.obs;
  var sizeChart = Rxn<SizeChartModel>();

  final SizeChartRepository _sizeChartRepository = SizeChartRepository();

  void toggleUnit() {
    isInches.value = !isInches.value;
  }

  void selectSize(String size) {
    selectedSize.value = size;
  }

  Future<void> loadSizeChartForProduct(Product product) async {
    try {
      isLoading.value = true;
      final chart = await _sizeChartRepository.getSizeChartForProduct(product);
      if (chart != null) {
        sizeChart.value = chart;
      } else {
        // Fallback to legacy charts
        await _loadLegacySizeChart(product);
      }
    } catch (e) {
      print('Error loading size chart: $e');
      // Fallback to legacy charts if database fails
      await _loadLegacySizeChart(product);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLegacySizeChart(Product product) async {
    try {
      // Use repository's enhanced legacy fallback
      final legacyChart = await _sizeChartRepository.getLegacyChartByCategory(
        product.categoryId,
      );

      if (legacyChart != null) {
        sizeChart.value = legacyChart;
      } else {
        // Final fallback to hardcoded charts
        final legacyCharts = SizeChartData.getSizeCharts();
        final categoryKey = _getCategoryKeyFromProduct(product);

        if (legacyCharts.containsKey(categoryKey)) {
          final chart = legacyCharts[categoryKey]!;
          sizeChart.value = SizeChartModel.fromLegacy(categoryKey, chart);
        } else {
          // Default fallback
          sizeChart.value = SizeChartModel.fromLegacy(
            'default',
            legacyCharts.values.first,
          );
        }
      }
    } catch (e) {
      print('Error loading legacy size chart: $e');
    }
  }

  String _getCategoryKeyFromProduct(Product product) {
    final productName = product.name.toLowerCase();

    // Footwear detection
    if (productName.contains('shoe') ||
        productName.contains('sneaker') ||
        productName.contains('boot') ||
        productName.contains('sandal') ||
        productName.contains('running') ||
        productName.contains('athletic')) {
      return 'footwear';
    }

    // Women's clothing detection
    if (productName.contains('dress') ||
        productName.contains('women') ||
        productName.contains('girl') ||
        productName.contains('yoga') ||
        productName.contains('legging') ||
        productName.contains('blouse')) {
      return 'womens_clothing';
    }

    // Accessories detection
    if (productName.contains('ring') ||
        productName.contains('bracelet') ||
        productName.contains('jewelry') ||
        productName.contains('accessory')) {
      return 'accessories';
    }

    // Default to men's clothing for most items
    return 'mens_clothing';
  }
}

class SizeChartButton extends StatelessWidget {
  final Product product;
  final List<String> availableSizes;

  const SizeChartButton({
    super.key,
    required this.product,
    required this.availableSizes,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this product category should show size chart
    if (!_shouldShowSizeChart()) {
      return const SizedBox.shrink(); // Hide size chart for non-applicable products
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => _showSizeChart(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.straighten, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Size Chart',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Determines if size chart should be shown for this product
  bool _shouldShowSizeChart() {
    final productName = product.name.toLowerCase();

    // Electronics and accessories that typically don't need size charts
    if (productName.contains('watch') ||
        productName.contains('phone') ||
        productName.contains('earbuds') ||
        productName.contains('charger') ||
        productName.contains('cable') ||
        productName.contains('power bank') ||
        productName.contains('speaker') ||
        productName.contains('tablet') ||
        productName.contains('laptop') ||
        productName.contains('headphone')) {
      return false;
    }

    // Only show for products with multiple meaningful sizes
    if (availableSizes.length <= 1) {
      // Check if the single size is a generic size like "One Size", "Free Size", etc.
      if (availableSizes.isNotEmpty) {
        final singleSize = availableSizes.first.toLowerCase();
        if (singleSize.contains('one size') ||
            singleSize.contains('free size') ||
            singleSize.contains('universal') ||
            singleSize == 'os' ||
            singleSize == 'onesize') {
          return false;
        }
      }
    }

    // Show size chart for clothing and items that typically need sizing
    if (productName.contains('shirt') ||
        productName.contains('dress') ||
        productName.contains('pant') ||
        productName.contains('jean') ||
        productName.contains('jacket') ||
        productName.contains('coat') ||
        productName.contains('sweater') ||
        productName.contains('hoodie') ||
        productName.contains('blazer') ||
        productName.contains('skirt') ||
        productName.contains('shorts') ||
        productName.contains('legging') ||
        productName.contains('yoga') ||
        productName.contains('shoe') ||
        productName.contains('sneaker') ||
        productName.contains('boot') ||
        productName.contains('sandal') ||
        productName.contains('sock') ||
        productName.contains('underwear') ||
        productName.contains('bra') ||
        productName.contains('swimwear')) {
      return true;
    }

    // Accessories that might need sizing
    if (productName.contains('ring') ||
        productName.contains('bracelet') ||
        productName.contains('glove') ||
        productName.contains('hat') ||
        productName.contains('cap') ||
        productName.contains('belt')) {
      return true;
    }

    // Default: if it has multiple sizes, show size chart
    return availableSizes.length > 1;
  }

  void _showSizeChart(BuildContext context) {
    final sizeChartController = Get.put(SizeChartController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SizeChartModal(
            product: product,
            availableSizes: availableSizes,
            controller: sizeChartController,
          ),
    );
  }
}

class SizeChartModal extends StatefulWidget {
  final Product product;
  final List<String> availableSizes;
  final SizeChartController controller;

  const SizeChartModal({
    super.key,
    required this.product,
    required this.availableSizes,
    required this.controller,
  });

  @override
  State<SizeChartModal> createState() => _SizeChartModalState();
}

class _SizeChartModalState extends State<SizeChartModal> {
  @override
  void initState() {
    super.initState();
    // Load size chart when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadSizeChartForProduct(widget.product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Obx(() {
        if (widget.controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final sizeChart = widget.controller.sizeChart.value;
        if (sizeChart == null) {
          return const Center(
            child: Text(
              'Size chart not available for this product',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: AppTheme.textPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sizeChart.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                sizeChart.chartType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sizeChart.category,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),

            // Unit toggle
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnitToggle('CM', !widget.controller.isInches.value, () {
                    if (widget.controller.isInches.value) {
                      widget.controller.toggleUnit();
                    }
                  }),
                  _buildUnitToggle(
                    'INCHES',
                    widget.controller.isInches.value,
                    () {
                      if (!widget.controller.isInches.value) {
                        widget.controller.toggleUnit();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Size Chart Table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.grey300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.grey200,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Size',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                ...sizeChart.measurementTypes.map(
                                  (type) => Expanded(
                                    flex: 3,
                                    child: Text(
                                      '$type ${widget.controller.isInches.value ? '(in)' : '(cm)'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.sizeChartHeaderText,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rows
                          ...sizeChart.entries.map(
                            (entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.grey200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        entry.size,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  ...sizeChart.measurementTypes.map((type) {
                                    final measurement =
                                        entry.measurements[type];
                                    if (measurement == null) {
                                      return const Expanded(
                                        flex: 3,
                                        child: Text(
                                          '-',
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }

                                    final value =
                                        widget.controller.isInches.value
                                            ? measurement.inches
                                            : measurement.cm;
                                    final unit =
                                        widget.controller.isInches.value
                                            ? '"'
                                            : '';

                                    return Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Instructions
                    if (sizeChart.measurementInstructions.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.infoBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.infoText,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Measurement Guide',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.infoText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sizeChart.measurementInstructions,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.infoTextSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildUnitToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
