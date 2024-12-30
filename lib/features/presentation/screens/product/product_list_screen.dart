import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_filter.dart' as filter;
import '../../controllers/product_controller.dart';
import '../../controllers/search_controller.dart';
import 'product_details_screen.dart';
import '../../../data/models/sort_option.dart' as sort;

class ProductListScreen extends StatelessWidget {
  final String title;
  final List<Product> products;
  final ProductController productController = Get.find();

  ProductListScreen({super.key, required this.title, required this.products}) {
    // Initialize filter ranges when screen is created
    productController.filterController.initializeFilterRanges(products);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => productController.showFilterBottomSheet(),
          ),
        ],
      ),
      body: Obx(() {
        final filter = productController.filterController.currentFilter.value;
        final filteredProducts = productController.filterController
            .filterProducts(products);
        final sortedProducts = productController.filterController.sortProducts(
          filteredProducts,
        );

        return Column(
          children: [
            if (filter.hasFilters) _buildActiveFilters(filter),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sortedProducts.length,
                itemBuilder: (context, index) {
                  final product = sortedProducts[index];
                  return Card(
                    child: InkWell(
                      onTap:
                          () => Get.to(
                            () => ProductDetailsScreen(product: product),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              child: Image.asset(
                                product.images[0],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActiveFilters(filter.ProductFilter filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              TextButton(
                onPressed:
                    () => productController.filterController.resetFilters(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (filter.priceRange != null)
                _buildFilterChip(
                  'Price: \$${filter.priceRange!.start.toStringAsFixed(0)} - \$${filter.priceRange!.end.toStringAsFixed(0)}',
                  () =>
                      productController.filterController.updatePriceRange(null),
                ),
              ...filter.categories.map(
                (category) => _buildFilterChip(
                  category,
                  () => productController.filterController.toggleCategory(
                    category,
                  ),
                ),
              ),
              ...filter.brands.map(
                (brand) => _buildFilterChip(
                  brand,
                  () => productController.filterController.toggleBrand(brand),
                ),
              ),
              if (filter.minRating != null)
                _buildFilterChip(
                  '${filter.minRating}+ Stars',
                  () => productController.filterController.updateRating(null),
                ),
              if (filter.inStock == true)
                _buildFilterChip(
                  'In Stock',
                  () => productController.filterController.toggleInStock(),
                ),
              if (filter.onSale == true)
                _buildFilterChip(
                  'On Sale',
                  () => productController.filterController.toggleOnSale(),
                ),
              if (filter.sortBy != sort.SortOption.newest)
                _buildFilterChip(
                  'Sort: ${filter.sortBy.displayName}',
                  () => productController.filterController.updateSortOption(
                    sort.SortOption.newest,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
      deleteIconColor: Theme.of(Get.context!).primaryColor,
      labelStyle: TextStyle(color: Theme.of(Get.context!).primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
