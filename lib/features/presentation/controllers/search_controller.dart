import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/analytics_service.dart';
import '../../data/models/product_model.dart';

enum SortOption { newest, priceHighToLow, priceLowToHigh, popularity }

class ProductFilter {
  final RangeValues priceRange;
  final List<String> categories;
  final double? minRating;

  ProductFilter({
    required this.priceRange,
    required this.categories,
    this.minRating,
  });
}

class SearchController extends GetxController {
  final supabase = Supabase.instance.client;
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  final RxList<Product> searchResults = <Product>[].obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<String> suggestions = <String>[].obs;
  final Rx<SortOption> currentSort = SortOption.newest.obs;
  final Rx<ProductFilter> currentFilter =
      ProductFilter(
        priceRange: const RangeValues(0, 1000),
        categories: [],
        minRating: null,
      ).obs;
  final RxList<Product> originalResults = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return;

    try {
      isLoading.value = true;
      final response = await supabase
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      originalResults.value =
          (response as List<dynamic>)
              .map((json) => Product.fromJson(json))
              .toList();

      _filterResults(); // This will update searchResults

      // Track search analytics
      await _analytics.trackSearch(
        query: query,
        resultCount: searchResults.length,
        userId: supabase.auth.currentUser?.id ?? 'anonymous',
        filters: {
          'price_range': {
            'start': currentFilter.value.priceRange.start,
            'end': currentFilter.value.priceRange.end,
          },
          'categories': currentFilter.value.categories,
          'min_rating': currentFilter.value.minRating,
          'sort_option': currentSort.value.toString(),
        },
      );

      addToRecentSearches(query);
    } catch (e) {
      print('Error searching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      suggestions.clear();
      return;
    }

    try {
      final response = await supabase
          .from('products')
          .select('name')
          .ilike('name', '%$query%')
          .limit(5);

      suggestions.value =
          (response as List<dynamic>)
              .map((json) => json['name'] as String)
              .toList();
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
    searchResults.value =
        originalResults.where((product) {
          final matchesPrice =
              product.price >= currentFilter.value.priceRange.start &&
              product.price <= currentFilter.value.priceRange.end;

          final matchesCategory =
              currentFilter.value.categories.isEmpty ||
              (product.categoryId != null &&
                  currentFilter.value.categories.contains(product.categoryId));

          final matchesRating =
              currentFilter.value.minRating == null ||
              product.rating >= currentFilter.value.minRating!;

          return matchesPrice && matchesCategory && matchesRating;
        }).toList();
  }
}
