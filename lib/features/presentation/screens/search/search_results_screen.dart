import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  SearchResultsScreen({super.key, required this.query}) {
    print('🟢 [SEARCH_RESULTS_SCREEN] Screen initialized with query: "$query"');
    print(
      '🟢 [SEARCH_RESULTS_SCREEN] Current searchResults count: ${_searchController.searchResults.length}',
    );
    print(
      '🟢 [SEARCH_RESULTS_SCREEN] Current originalResults count: ${_searchController.originalResults.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Log when build is called
    print('🟢 [SEARCH_RESULTS_SCREEN] build() called for query: "$query"');
    print(
      '🟢 [SEARCH_RESULTS_SCREEN] isLoading: ${_searchController.isLoading.value}',
    );
    print(
      '🟢 [SEARCH_RESULTS_SCREEN] searchResults.length: ${_searchController.searchResults.length}',
    );

    // Log all products being displayed
    if (_searchController.searchResults.isNotEmpty) {
      print('🟢 [SEARCH_RESULTS_SCREEN] Products to display:');
      for (int i = 0; i < _searchController.searchResults.length; i++) {
        final product = _searchController.searchResults[i];
        print(
          '🟢 [SEARCH_RESULTS_SCREEN]   [$i] ID: ${product.id}, Name: "${product.name}", Price: ${product.price}',
        );
      }
    }
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

        final resultsCount = _searchController.searchResults.length;
        print(
          '🟢 [SEARCH_RESULTS_SCREEN] Building ListView with $resultsCount products for query: "$query"',
        );

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: resultsCount,
          itemBuilder: (context, index) {
            final product = _searchController.searchResults[index];
            if (index == 0) {
              print(
                '🟢 [SEARCH_RESULTS_SCREEN] Rendering first product: "${product.name}" (ID: ${product.id})',
              );
            }
            if (index == resultsCount - 1) {
              print(
                '🟢 [SEARCH_RESULTS_SCREEN] Rendering last product: "${product.name}" (ID: ${product.id})',
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildSlimProductCard(product),
            );
          },
        );
      }),
    );
  }

  Widget _buildSlimProductCard(Product product) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed('/product-details', arguments: product.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Section (Left)
              _buildProductImage(product),
              const SizedBox(width: 12),
              // Product Details Section (Right)
              Expanded(child: _buildProductDetails(product)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    String imageUrl = '';

    // Get the best available image URL
    if (product.primaryImage.isNotEmpty) {
      imageUrl = product.primaryImage;
    } else if (product.imageList.isNotEmpty) {
      imageUrl = product.imageList.first;
    }

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
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
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                    )
                    : Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
          ),
        ),
        // Sale Badge
        if (product.isOnSale)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SALE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetails(Product product) {
    return SizedBox(
      height: 120, // Fixed height to match image height
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Product Name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // Brand/Vendor (if available)
          if (product.vendor?.businessName != null) ...[
            Text(
              product.vendor!.businessName,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          // Price and Rating Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rating
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppTheme.ratingStars,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (product.reviews > 0) ...[
                    Text(
                      ' (${product.reviews})',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              // Price
              Flexible(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (product.isOnSale && product.salePrice != null) ...[
                        Text(
                          _currencyController.getFormattedProductPrice(
                            product.price,
                            product.currency,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyController.getFormattedProductPrice(
                            product.salePrice!,
                            product.currency,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else
                        Text(
                          _currencyController.getFormattedProductPrice(
                            product.price,
                            product.currency,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
