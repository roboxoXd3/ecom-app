import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/search_controller.dart';
import '../../controllers/search_controller.dart' as app;
import '../../controllers/currency_controller.dart';
import '../../screens/search/filter_dialog.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final app.SearchController _searchController =
      Get.find<app.SearchController>();
  final CurrencyController _currencyController = Get.find<CurrencyController>();

  SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                query == 'Image Search'
                    ? 'Image Search Results'
                    : 'Results for "$query"',
                style: const TextStyle(fontSize: 16),
              ),
              // Show image search indicator
              if (_searchController.selectedImage.value != null)
                const Text(
                  '🖼️ Searched by image',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
            ],
          ),
        ),
        actions: [
          // Show selected image thumbnail if available
          Obx(
            () =>
                _searchController.selectedImage.value != null
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => _showImagePreview(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _searchController.selectedImage.value!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Get.bottomSheet(const FilterDialog(), isScrollControlled: true);
            },
          ),
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortOptions),
        ],
      ),
      body: Obx(() {
        if (_searchController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_searchController.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 120, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$query"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try checking your spelling or using different keywords',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _searchController.searchResults.length,
          itemBuilder: (context, index) {
            final product = _searchController.searchResults[index];
            return _buildProductCard(product);
          },
        );
      }),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Get.toNamed('/product-details', arguments: product.id),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child:
                    product.primaryImage.isNotEmpty
                        ? Image.network(
                          product.primaryImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                        )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      _currencyController.getFormattedProductPrice(
                        product.price,
                        product.currency,
                      ),
                      style: TextStyle(
                        color: Theme.of(Get.context!).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppTheme.ratingStars,
                      ),
                      Text(
                        ' ${product.rating}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        ' (${product.reviews})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...SortOption.values.map(
              (option) => ListTile(
                title: Text(_getSortOptionText(option)),
                leading: Radio<SortOption>(
                  value: option,
                  groupValue: _searchController.currentSort.value,
                  onChanged: (SortOption? value) {
                    if (value != null) {
                      _searchController.sortResults(value);
                      Get.back();
                    }
                  },
                ),
                onTap: () {
                  _searchController.sortResults(option);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.popularity:
        return 'Most Popular';
    }
  }

  /// Show image preview dialog
  void _showImagePreview() {
    if (_searchController.selectedImage.value == null) return;

    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Search Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.file(_searchController.selectedImage.value!),
            ),
          ],
        ),
      ),
    );
  }
}
