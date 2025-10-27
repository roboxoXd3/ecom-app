import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_filter.dart' as filter;
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../../../core/utils/currency_utils.dart';

import '../../../data/models/sort_option.dart' as sort;

class ProductListScreen extends StatelessWidget {
  final String title;
  final ProductController productController = Get.find();
  final CurrencyController currencyController = Get.find();

  ProductListScreen({super.key, required this.title});

  Widget _buildProductImage(Product product) {
    String imageUrl = '';

    // Get the best available image URL
    if (product.primaryImage.isNotEmpty) {
      imageUrl = product.primaryImage;
    } else if (product.imageList.isNotEmpty) {
      imageUrl = product.imageList.first;
    }

    // If no valid image URL, show placeholder
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch products when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productController.allProducts.isEmpty) {
        productController.fetchAllProducts();
      }
    });

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
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final filter = productController.currentFilter.value;
        final filteredProducts = productController.filterProducts(
          productController.allProducts,
        );
        final sortedProducts = productController.sortProducts(filteredProducts);

        if (sortedProducts.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return Column(
          children: [
            if (filter.hasFilters) _buildActiveFilters(filter),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => productController.fetchAllProducts(),
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
                            () => Get.toNamed(
                              '/product-details',
                              arguments: product.id,
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                child: _buildProductImage(product),
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
                                  Obx(
                                    () => Text(
                                      currencyController
                                          .getFormattedProductPrice(
                                            product.price,
                                            product.currency,
                                          ),
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                onPressed: () => productController.resetFilters(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (filter.priceRange != null)
                Obx(
                  () => _buildFilterChip(
                    'Price: ${CurrencyUtils.formatPriceRange(filter.priceRange!.start, filter.priceRange!.end)}',
                    () => productController.updatePriceRange(null),
                  ),
                ),
              ...filter.categories.map(
                (category) => _buildFilterChip(
                  category,
                  () => productController.toggleCategory(category),
                ),
              ),
              ...filter.brands.map(
                (brand) => _buildFilterChip(
                  brand,
                  () => productController.toggleBrand(brand),
                ),
              ),
              if (filter.minRating != null)
                _buildFilterChip(
                  '${filter.minRating}+ Stars',
                  () => productController.updateRating(null),
                ),
              if (filter.inStock == true)
                _buildFilterChip(
                  'In Stock',
                  () => productController.toggleInStock(),
                ),
              if (filter.onSale == true)
                _buildFilterChip(
                  'On Sale',
                  () => productController.toggleOnSale(),
                ),
              if (filter.sortBy != sort.SortOption.newest)
                _buildFilterChip(
                  'Sort: ${filter.sortBy.displayName}',
                  () => productController.updateSortOption(
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
