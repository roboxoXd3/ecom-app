import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../../../core/theme/app_theme.dart';

class FilterBottomSheet extends StatelessWidget {
  final Category category;
  final ProductController productController;
  final RxDouble minPrice;
  final RxDouble maxPrice;
  final RxList<String> selectedBrands;
  final RxDouble minRating;
  final RxBool showOnSaleOnly;
  final RxBool showInStockOnly;
  final RxString sortBy;
  final VoidCallback onResetFilters;

  const FilterBottomSheet({
    super.key,
    required this.category,
    required this.productController,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedBrands,
    required this.minRating,
    required this.showOnSaleOnly,
    required this.showInStockOnly,
    required this.sortBy,
    required this.onResetFilters,
  });

  static void show(
    BuildContext context,
    Category category,
    ProductController productController,
    RxDouble minPrice,
    RxDouble maxPrice,
    RxList<String> selectedBrands,
    RxDouble minRating,
    RxBool showOnSaleOnly,
    RxBool showInStockOnly,
    RxString sortBy,
    VoidCallback onResetFilters,
  ) {
    // Initialize filter ranges based on category products
    final categoryProducts =
        productController.allProducts
            .where((product) => product.categoryId == category.id)
            .toList();

    if (categoryProducts.isNotEmpty) {
      final prices = categoryProducts.map((p) => p.price).toList();
      minPrice.value = prices.reduce((a, b) => a < b ? a : b);
      maxPrice.value = prices.reduce((a, b) => a > b ? a : b);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FilterBottomSheet(
            category: category,
            productController: productController,
            minPrice: minPrice,
            maxPrice: maxPrice,
            selectedBrands: selectedBrands,
            minRating: minRating,
            showOnSaleOnly: showOnSaleOnly,
            showInStockOnly: showInStockOnly,
            sortBy: sortBy,
            onResetFilters: onResetFilters,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProducts =
        productController.allProducts
            .where((product) => product.categoryId == category.id)
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getBorder(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                TextButton(
                  onPressed: onResetFilters,
                  child: const Text('Reset All'),
                ),
              ],
            ),
          ),
          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  _buildPriceRangeFilter(context),
                  const SizedBox(height: 24),
                  // Brands
                  _buildBrandsFilter(context, categoryProducts),
                  const SizedBox(height: 24),
                  // Rating
                  _buildRatingFilter(context),
                  const SizedBox(height: 24),
                  // Toggles
                  _buildToggleFilters(),
                  const SizedBox(height: 24),
                  // Sort Options
                  _buildSortOptions(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => RangeSlider(
            values: RangeValues(minPrice.value, maxPrice.value),
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '₹${minPrice.value.round()}',
              '₹${maxPrice.value.round()}',
            ),
            onChanged: (RangeValues values) {
              minPrice.value = values.start;
              maxPrice.value = values.end;
            },
          ),
        ),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${minPrice.value.round()}',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
              Text(
                '₹${maxPrice.value.round()}',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsFilter(
    BuildContext context,
    List<Product> categoryProducts,
  ) {
    final availableBrands =
        categoryProducts.map((p) => p.brand).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brands',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        if (availableBrands.isEmpty)
          Text(
            'No brands available',
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontSize: 14,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableBrands.map((brand) {
                  return Obx(() {
                    final isSelected = selectedBrands.contains(brand);
                    return FilterChip(
                      label: Text(brand),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          selectedBrands.add(brand);
                        } else {
                          selectedBrands.remove(brand);
                        }
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  });
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  minRating.value = (index + 1).toDouble();
                },
                icon: Icon(
                  index < minRating.value ? Icons.star : Icons.star_border,
                  color: AppTheme.ratingStars,
                  size: 28,
                ),
              );
            }),
          ),
        ),
        Obx(
          () => Text(
            minRating.value > 0
                ? '${minRating.value.toInt()}+ stars'
                : 'Any rating',
            style: TextStyle(
              color: AppTheme.getTextSecondary(context),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleFilters() {
    return Column(
      children: [
        Obx(
          () => SwitchListTile(
            title: const Text('On Sale Only'),
            subtitle: const Text('Show only discounted products'),
            value: showOnSaleOnly.value,
            onChanged: (value) => showOnSaleOnly.value = value,
            activeColor: AppTheme.primaryColor,
          ),
        ),
        Obx(
          () => SwitchListTile(
            title: const Text('In Stock Only'),
            subtitle: const Text('Show only available products'),
            value: showInStockOnly.value,
            onChanged: (value) => showInStockOnly.value = value,
            activeColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    final sortOptions = [
      {'value': 'newest', 'label': 'Newest First'},
      {'value': 'price_low_high', 'label': 'Price: Low to High'},
      {'value': 'price_high_low', 'label': 'Price: High to Low'},
      {'value': 'rating', 'label': 'Highest Rated'},
      {'value': 'name', 'label': 'Name A-Z'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        ...sortOptions.map((option) {
          return Obx(
            () => RadioListTile<String>(
              title: Text(option['label']!),
              value: option['value']!,
              groupValue: sortBy.value,
              onChanged: (value) {
                if (value != null) {
                  sortBy.value = value;
                }
              },
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
          );
        }),
      ],
    );
  }
}
