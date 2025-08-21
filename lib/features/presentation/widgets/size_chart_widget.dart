import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/size_chart_model.dart';
import '../../data/models/product_model.dart' as ProductModule;
import '../../data/repositories/size_chart_repository.dart';
import '../../../core/theme/app_theme.dart';

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

  Future<void> loadSizeChartForProduct(ProductModule.Product product) async {
    try {
      isLoading.value = true;
      final chart = await _sizeChartRepository.getSizeChartForProduct(product);
      sizeChart.value = chart;
    } catch (e) {
      print('Error loading size chart: $e');
      // Fallback to legacy charts if database fails
      _loadLegacySizeChart(product);
    } finally {
      isLoading.value = false;
    }
  }

  void _loadLegacySizeChart(ProductModule.Product product) {
    try {
      // Determine chart type based on category or product type
      String chartKey = _getCategoryChartKey(product.categoryId);
      final legacyCharts = SizeChartData.getSizeCharts();

      if (legacyCharts.containsKey(chartKey)) {
        final legacyChart = legacyCharts[chartKey]!;
        sizeChart.value = SizeChartModel.fromLegacy(chartKey, legacyChart);
      } else {
        // Default fallback
        sizeChart.value = SizeChartModel.fromLegacy(
          'default',
          legacyCharts.values.first,
        );
      }
    } catch (e) {
      print('Error loading legacy size chart: $e');
    }
  }

  String _getCategoryChartKey(String categoryId) {
    // Map database category IDs to legacy chart keys
    // You'll need to customize this mapping based on your actual category IDs
    // For now, this is a simple fallback mapping
    return 'mens_clothing'; // Default fallback
  }

  @override
  void onClose() {
    super.onClose();
  }
}

class SizeChartButton extends StatelessWidget {
  final ProductModule.Product product;
  final List<String> availableSizes;

  const SizeChartButton({
    super.key,
    required this.product,
    required this.availableSizes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => _showSizeChart(context, product),
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
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 14, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeChart(BuildContext context, ProductModule.Product product) {
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
  final ProductModule.Product product;
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
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        );
      }

      final sizeChart = widget.controller.sizeChart.value;
      if (sizeChart == null) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Center(
            child: Text(
              'Size chart not available for this product',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }

      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Size Chart',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            sizeChart.category,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  // Unit toggle
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildUnitToggle(
                            'CM',
                            !widget.controller.isInches.value,
                            () {
                              if (widget.controller.isInches.value) {
                                widget.controller.toggleUnit();
                              }
                            },
                          ),
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
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab bar
                    Container(
                      color: Colors.grey[50],
                      child: TabBar(
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: AppTheme.primaryColor,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Size Chart'),
                          Tab(text: 'How to Measure'),
                        ],
                      ),
                    ),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSizeChartTab(sizeChart),
                          _buildMeasurementGuideTab(sizeChart),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUnitToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeChartTab(SizeChartModel sizeChart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size recommendations
          if (sizeChart.sizeRecommendations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Size Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...sizeChart.sizeRecommendations.entries
                      .where(
                        (entry) => widget.availableSizes.contains(entry.key),
                      )
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      widget.availableSizes.contains(entry.key)
                                          ? AppTheme.primaryColor
                                          : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Text(
                                    'S', // entry.key
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
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
            const SizedBox(height: 24),
          ],

          // Simple size chart table
          const Text(
            'Size Chart Table',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Basic table
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Size',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Chest',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Waist',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...sizeChart.entries.map(
                  (entry) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.size)),
                        Expanded(
                          child: Text(
                            '${entry.measurements.values.first.cm} cm',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.measurements.values.first.cm} cm',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementGuideTab(SizeChartModel sizeChart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Measurement instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Measurement Guide',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sizeChart.measurementInstructions,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Our size experts are here to help you find the perfect fit.',
                        style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to customer support
                    Get.snackbar(
                      'Support',
                      'Redirecting to customer support...',
                      backgroundColor: Colors.blue[700],
                      colorText: Colors.white,
                    );
                  },
                  child: Text(
                    'Contact Us',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
