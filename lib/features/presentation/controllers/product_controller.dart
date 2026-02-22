import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_filter.dart';
import '../../data/models/sort_option.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../../core/utils/snackbar_utils.dart';

class ProductController extends GetxController {
  final ProductRepository _repository = ProductRepository();
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final RxBool isLoading = false.obs;
  final RxList<Product> allProducts = <Product>[].obs;
  final RxList<Product> newArrivals = <Product>[].obs;
  final RxList<Product> featuredProducts = <Product>[].obs;
  final RxList<Product> wishlist = <Product>[].obs;
  final RxSet<String> wishlistProductIds = <String>{}.obs;

  // Filter related variables
  final Rx<ProductFilter> currentFilter = ProductFilter().obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;

  void initializeFilterRanges(List<Product> products) {
    if (products.isEmpty) return;

    minPrice.value = products.map((p) => p.price).reduce(min);
    maxPrice.value = products.map((p) => p.price).reduce(max);
    currentFilter.value = ProductFilter(
      priceRange: RangeValues(minPrice.value, maxPrice.value),
    );
  }

  List<Product> filterProducts(List<Product> products) {
    return products.where((product) {
      // Price filter
      if (currentFilter.value.priceRange != null) {
        if (product.price < currentFilter.value.priceRange!.start ||
            product.price > currentFilter.value.priceRange!.end) {
          return false;
        }
      }

      // Category filter
      if (currentFilter.value.categories.isNotEmpty) {
        if (!currentFilter.value.categories.contains(product.categoryId)) {
          return false;
        }
      }

      // Brand filter
      if (currentFilter.value.brands.isNotEmpty) {
        if (!currentFilter.value.brands.contains(product.brand)) {
          return false;
        }
      }

      // Rating filter
      if (currentFilter.value.minRating != null) {
        if (product.rating < currentFilter.value.minRating!) {
          return false;
        }
      }

      // Stock filter
      if (currentFilter.value.inStock != null) {
        if (product.inStock != currentFilter.value.inStock) {
          return false;
        }
      }

      // Sale filter
      if (currentFilter.value.onSale != null) {
        if (product.isOnSale != currentFilter.value.onSale) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Product> sortProducts(List<Product> products) {
    switch (currentFilter.value.sortBy) {
      case SortOption.priceHighToLow:
        return List.from(products)..sort((a, b) => b.price.compareTo(a.price));
      case SortOption.priceLowToHigh:
        return List.from(products)..sort((a, b) => a.price.compareTo(b.price));
      case SortOption.rating:
        return List.from(products)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.newest:
      default:
        return List.from(products)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  void showFilterBottomSheet() {
    // Implement your filter bottom sheet here
    // You can create a separate widget for this
  }

  void updatePriceRange(RangeValues? range) {
    currentFilter.update((val) {
      val?.priceRange = range;
    });
  }

  void toggleCategory(String category) {
    currentFilter.update((val) {
      if (val?.categories.contains(category) ?? false) {
        val?.categories.remove(category);
      } else {
        val?.categories.add(category);
      }
    });
  }

  void toggleBrand(String brand) {
    currentFilter.update((val) {
      if (val?.brands.contains(brand) ?? false) {
        val?.brands.remove(brand);
      } else {
        val?.brands.add(brand);
      }
    });
  }

  void updateRating(double? rating) {
    currentFilter.update((val) {
      val?.minRating = rating;
    });
  }

  void toggleInStock() {
    currentFilter.update((val) {
      val?.inStock = !(val.inStock ?? false);
    });
  }

  void toggleOnSale() {
    currentFilter.update((val) {
      val?.onSale = !(val.onSale ?? false);
    });
  }

  void updateSortOption(SortOption option) {
    currentFilter.update((val) {
      val?.sortBy = option;
    });
  }

  void resetFilters() {
    currentFilter.value = ProductFilter();
  }

  // void toggleWishlist(Product product) {
  //   if (wishlist.contains(product)) {
  //     wishlist.remove(product);
  //   } else {
  //     wishlist.add(product);
  //   }
  // }

  @override
  void onInit() {
    super.onInit();
    loadWishlist();
  }

  Future<void> fetchAllProducts() async {
    isLoading.value = true;
    print('ProductController: fetchAllProducts started');

    final productsFuture = _repository.getProducts().then((products) {
      allProducts.value = products;
      print('ProductController: allProducts loaded (${products.length})');
      isLoading.value = false;
    });

    final newArrivalsFuture = _repository.getNewArrivals().then((products) {
      newArrivals.value = products;
      print('ProductController: newArrivals loaded (${products.length})');
    });

    final featuredFuture = _repository.getFeaturedProducts().then((products) {
      featuredProducts.value = products;
      print('ProductController: featured loaded (${products.length})');
    });

    await Future.wait([productsFuture, newArrivalsFuture, featuredFuture]);
  }

  Future<List<Product>> getNewArrivals() async {
    if (newArrivals.isEmpty) {
      try {
        final products = await _repository.getNewArrivals();
        newArrivals.value = products;
      } catch (e) {
        print('Error fetching new arrivals: $e');
        return [];
      }
    }
    return newArrivals;
  }

  Future<List<Product>> getFeaturedProducts() async {
    if (featuredProducts.isEmpty) {
      try {
        final products = await _repository.getFeaturedProducts();
        featuredProducts.value = products;
      } catch (e) {
        print('Error fetching featured products: $e');
        return [];
      }
    }
    return featuredProducts;
  }

  // Method to refresh all data
  Future<void> refreshProducts() async {
    await fetchAllProducts();
  }

  Future<void> loadWishlist() async {
    try {
      final ids = await _wishlistRepository.getWishlistProductIds();
      wishlistProductIds.value = ids.toSet();
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> toggleWishlist(Product product) async {
    try {
      if (wishlistProductIds.contains(product.id)) {
        await _wishlistRepository.removeFromWishlist(product.id);
        wishlistProductIds.remove(product.id);
        wishlist.remove(product);
        SnackbarUtils.showSuccess('Removed from wishlist');
      } else {
        await _wishlistRepository.addToWishlist(product.id);
        wishlistProductIds.add(product.id);
        wishlist.add(product);
        SnackbarUtils.showSuccess('Added to wishlist');
      }
    } catch (e) {
      print('Error toggling wishlist: $e');
      SnackbarUtils.showError('Failed to update wishlist. Please try again.');
    }
  }

  bool isInWishlist(String productId) {
    return wishlistProductIds.contains(productId);
  }
}
