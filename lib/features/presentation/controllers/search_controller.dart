import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/auth_service.dart';
import '../../data/models/product_model.dart';
import '../../data/services/product_search_service.dart';

enum SortOption { newest, priceHighToLow, priceLowToHigh, popularity }

class ProductFilter {
  final RangeValues priceRange;
  final List<String> categories;
  final List<String> vendors;
  final double? minRating;

  ProductFilter({
    required this.priceRange,
    required this.categories,
    required this.vendors,
    this.minRating,
  });
}

class SearchController extends GetxController {
  final AnalyticsService _analytics = Get.find<AnalyticsService>();
  final ProductSearchService _searchService = ProductSearchService();

  final RxList<Product> searchResults = <Product>[].obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> suggestions = <Map<String, dynamic>>[].obs;
  final Rx<SortOption> currentSort = SortOption.newest.obs;
  final Rx<ProductFilter> currentFilter =
      ProductFilter(
        priceRange: const RangeValues(
          0,
          double.infinity,
        ), // No price limit by default - filters only apply when user explicitly sets them
        categories: [],
        vendors: [],
        minRating: null,
      ).obs;
  final RxList<Product> originalResults = <Product>[].obs;

  // Image search related variables
  final RxBool isImageSearching = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString imageSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return;

    print(
      '🟡 [SEARCH_CONTROLLER] searchProducts() called with query: "$query"',
    );
    print(
      '🟡 [SEARCH_CONTROLLER] Before search - searchResults: ${searchResults.length}, originalResults: ${originalResults.length}',
    );

    try {
      isLoading.value = true;

      // Clear previous results immediately to prevent showing stale data
      searchResults.clear();
      originalResults.clear();
      print('🟡 [SEARCH_CONTROLLER] Cleared previous results');

      // Reset filters to default when starting a new search
      // This ensures filters from previous searches don't affect new results
      // No price limit by default - filters only apply when user explicitly sets them
      currentFilter.value = ProductFilter(
        priceRange: const RangeValues(
          0,
          double.infinity,
        ), // No price limit - show all products
        categories: [],
        vendors: [],
        minRating: null,
      );
      print('🟡 [SEARCH_CONTROLLER] Reset filters to default (no price limit)');

      // Use hybrid search for better results combining keyword and semantic search
      // Build filters map, only including max_price if it's not infinity (no limit)
      final filtersMap = <String, dynamic>{
        'min_price': currentFilter.value.priceRange.start,
        if (currentFilter.value.priceRange.end != double.infinity)
          'max_price': currentFilter.value.priceRange.end,
        'categories': currentFilter.value.categories,
        'vendors': currentFilter.value.vendors,
        if (currentFilter.value.minRating != null)
          'min_rating': currentFilter.value.minRating,
      };

      originalResults.value = await _searchService.hybridSearch(
        query: query,
        limit: 50,
        filters: filtersMap.isEmpty ? null : filtersMap,
      );

      print(
        '🟡 [SEARCH_CONTROLLER] After hybridSearch - originalResults: ${originalResults.length}',
      );
      _filterResults(); // This will update searchResults
      print(
        '🟡 [SEARCH_CONTROLLER] After _filterResults() - searchResults: ${searchResults.length}',
      );

      // Log first few products for verification
      if (searchResults.isNotEmpty) {
        print('🟡 [SEARCH_CONTROLLER] First 3 products in searchResults:');
        for (
          int i = 0;
          i < (searchResults.length > 3 ? 3 : searchResults.length);
          i++
        ) {
          print(
            '🟡 [SEARCH_CONTROLLER]   [$i] "${searchResults[i].name}" (ID: ${searchResults[i].id})',
          );
        }
      }

      // Track search analytics
      try {
        print(
          '🔍 Tracking search analytics for: "$query" with ${searchResults.length} results',
        );
        await _analytics.trackSearch(
          query: query,
          resultCount: searchResults.length,
          userId: AuthService.isAuthenticated() ? AuthService.getCurrentUserId() : 'anonymous',
          filters: {
            'price_range': {
              'start': currentFilter.value.priceRange.start,
              'end': currentFilter.value.priceRange.end,
            },
            'categories': currentFilter.value.categories,
            'vendors': currentFilter.value.vendors,
            'min_rating': currentFilter.value.minRating,
            'sort_option': currentSort.value.toString(),
          },
        );
        print('✅ Search analytics tracked successfully');
      } catch (e) {
        print('❌ Error tracking search analytics: $e');
      }

      addToRecentSearches(query);
    } catch (e) {
      print('Error searching products: $e');
      // Ensure results are cleared on error to prevent showing incorrect data
      searchResults.clear();
      originalResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Search products using image
  Future<void> searchProductsByImage(File imageFile) async {
    try {
      isImageSearching.value = true;
      isLoading.value = true;
      selectedImage.value = imageFile;

      // Clear previous results immediately to prevent showing stale data
      searchResults.clear();
      originalResults.clear();

      print('🖼️ Starting image-based product search...');

      // Use the existing searchByImage method from ProductSearchService
      originalResults.value = await _searchService.searchByImage(
        imageFile: imageFile,
        limit: 50,
      );

      _filterResults(); // This will update searchResults

      // Track image search analytics
      try {
        await _analytics.trackSearch(
          query: 'Image Search',
          resultCount: searchResults.length,
          userId: AuthService.isAuthenticated() ? AuthService.getCurrentUserId() : 'anonymous',
          filters: {
            'search_type': 'image',
            'image_size_mb': _getFileSizeInMB(imageFile),
          },
        );
        print('✅ Image search analytics tracked successfully');
      } catch (e) {
        print('❌ Error tracking image search analytics: $e');
      }

      // Add to recent searches with a special indicator
      addToRecentSearches('🖼️ Image Search');
    } catch (e) {
      print('❌ Error in image search: $e');
      // Ensure results are cleared on error to prevent showing incorrect data
      searchResults.clear();
      originalResults.clear();
      Get.snackbar(
        'Search Error',
        'Failed to search products by image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isImageSearching.value = false;
      isLoading.value = false;
    }
  }

  /// Helper method to get file size in MB
  double _getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Clear image search state
  void clearImageSearch() {
    selectedImage.value = null;
    imageSearchQuery.value = '';
  }

  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      suggestions.clear();
      return;
    }

    try {
      final searchSuggestions = await _searchService.getSearchSuggestions(
        query,
      );
      suggestions.value = searchSuggestions;
    } catch (e) {
      print('Error getting suggestions: $e');
      suggestions.clear();
    }
  }

  void addToRecentSearches(String query) {
    if (!recentSearches.contains(query)) {
      recentSearches.insert(0, query);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
      saveRecentSearches();
    }
  }

  void clearRecentSearches() {
    recentSearches.clear();
    // Clear from local storage
    Get.find<GetStorage>().remove('recent_searches');
  }

  void loadRecentSearches() {
    final storage = Get.find<GetStorage>();
    final saved = storage.read<List>('recent_searches');
    if (saved != null) {
      recentSearches.value = saved.map((e) => e.toString()).toList();
    }
  }

  void saveRecentSearches() {
    final storage = Get.find<GetStorage>();
    storage.write('recent_searches', recentSearches.toList());
  }

  void sortResults(SortOption option) {
    currentSort.value = option;
    switch (option) {
      case SortOption.newest:
        searchResults.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortOption.priceHighToLow:
        searchResults.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.priceLowToHigh:
        searchResults.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.popularity:
        searchResults.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
  }

  void applyFilters(ProductFilter filter) {
    currentFilter.value = filter;
    _filterResults();
  }

  void _filterResults() {
    print('🔍 Filtering ${originalResults.length} products');

    // Format price range for logging
    final maxPrice =
        currentFilter.value.priceRange.end == double.infinity
            ? 'No limit'
            : currentFilter.value.priceRange.end.toString();
    print(
      '🔍 Current filter - Price: ${currentFilter.value.priceRange.start}-$maxPrice, Categories: ${currentFilter.value.categories.length}, Vendors: ${currentFilter.value.vendors.length}, MinRating: ${currentFilter.value.minRating}',
    );

    searchResults.value =
        originalResults.where((product) {
          // Handle infinity for max price (no upper limit)
          final maxPrice =
              currentFilter.value.priceRange.end == double.infinity
                  ? double.infinity
                  : currentFilter.value.priceRange.end;

          final matchesPrice =
              product.price >= currentFilter.value.priceRange.start &&
              (maxPrice == double.infinity || product.price <= maxPrice);

          final matchesCategory =
              currentFilter.value.categories.isEmpty ||
              (currentFilter.value.categories.contains(product.categoryId));

          final matchesVendor =
              currentFilter.value.vendors.isEmpty ||
              (currentFilter.value.vendors.contains(product.vendorId));

          final matchesRating =
              currentFilter.value.minRating == null ||
              product.rating >= currentFilter.value.minRating!;

          final matches =
              matchesPrice && matchesCategory && matchesVendor && matchesRating;

          if (!matches) {
            print(
              '❌ Product "${product.name}" filtered out - Price: ${product.price} (${matchesPrice ? "✓" : "✗"}), Category: ${matchesCategory ? "✓" : "✗"}), Vendor: ${matchesVendor ? "✓" : "✗"}), Rating: ${product.rating} (${matchesRating ? "✓" : "✗"})',
            );
          }

          return matches;
        }).toList();

    print('✅ Filtered to ${searchResults.length} products');
  }
}
