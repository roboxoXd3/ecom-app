import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_filter.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sort_option.dart' as sort;

class FilterController extends GetxController {
  final Rx<ProductFilter> currentFilter = ProductFilter().obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxList<String> availableBrands = <String>[].obs;
  final RxList<String> availableVendors = <String>[].obs;
  final RxDouble maxPrice = 0.0.obs;
  final RxDouble minPrice = 0.0.obs;

  void initializeFilterRanges(List<Product> products) {
    if (products.isEmpty) return;

    // Initialize price range
    maxPrice.value = products
        .map((p) => p.price)
        .reduce((max, price) => price > max ? price : max);
    minPrice.value = products
        .map((p) => p.price)
        .reduce((min, price) => price < min ? price : min);

    // Initialize available brands
    availableBrands.value = products.map((p) => p.brand).toSet().toList();

    // Initialize available vendors
    availableVendors.value =
        products
            .where((p) => p.vendor != null)
            .map((p) => p.vendor!.businessName)
            .toSet()
            .toList();

    // Set initial price range
    currentFilter.update((filter) {
      filter?.priceRange = RangeValues(minPrice.value, maxPrice.value);
    });
  }

  void applyFilter(ProductFilter filter) {
    currentFilter.value = filter;
  }

  void resetFilters() {
    currentFilter.value = ProductFilter(
      priceRange: RangeValues(minPrice.value, maxPrice.value),
    );
  }

  void updatePriceRange(RangeValues? range) {
    currentFilter.update((filter) {
      filter?.priceRange = range ?? RangeValues(minPrice.value, maxPrice.value);
    });
  }

  void toggleCategory(String category) {
    final categories = List<String>.from(currentFilter.value.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    currentFilter.update((filter) {
      filter?.categories = categories.toSet();
    });
  }

  void toggleBrand(String brand) {
    final brands = List<String>.from(currentFilter.value.brands);
    if (brands.contains(brand)) {
      brands.remove(brand);
    } else {
      brands.add(brand);
    }
    currentFilter.update((filter) {
      filter?.brands = brands.toSet();
    });
  }

  void toggleVendor(String vendorName) {
    final vendors = List<String>.from(currentFilter.value.vendors);
    if (vendors.contains(vendorName)) {
      vendors.remove(vendorName);
    } else {
      vendors.add(vendorName);
    }
    currentFilter.update((filter) {
      filter?.vendors = vendors.toSet();
    });
  }

  void updateRating(double? rating) {
    currentFilter.update((filter) {
      filter?.minRating = rating;
    });
  }

  void toggleInStock() {
    currentFilter.update((filter) {
      filter?.inStock = !(filter.inStock ?? false);
    });
  }

  void toggleOnSale() {
    currentFilter.update((filter) {
      filter?.onSale = !(filter.onSale ?? false);
    });
  }

  void updateSortOption(sort.SortOption option) {
    currentFilter.update((filter) {
      filter?.sortBy = option;
    });
  }

  List<Product> filterProducts(List<Product> products) {
    return products.where((product) {
      final filter = currentFilter.value;

      // Price Range Filter
      if (filter.priceRange != null) {
        if (product.price < filter.priceRange!.start ||
            product.price > filter.priceRange!.end) {
          return false;
        }
      }

      // Categories Filter
      if (filter.categories.isNotEmpty) {
        if (!filter.categories.contains(product.categoryId)) {
          return false;
        }
      }

      // Brands Filter
      if (filter.brands.isNotEmpty) {
        if (!filter.brands.contains(product.brand)) {
          return false;
        }
      }

      // Vendors Filter
      if (filter.vendors.isNotEmpty) {
        if (product.vendor == null ||
            !filter.vendors.contains(product.vendor!.businessName)) {
          return false;
        }
      }

      // Rating Filter
      if (filter.minRating != null) {
        if (product.rating < filter.minRating!) {
          return false;
        }
      }

      // Stock Filter
      if (filter.inStock != null) {
        if (product.inStock != filter.inStock) {
          return false;
        }
      }

      // Sale Filter
      if (filter.onSale != null) {
        if (product.isOnSale != filter.onSale) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Product> sortProducts(List<Product> products) {
    switch (currentFilter.value.sortBy) {
      case sort.SortOption.priceLowToHigh:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case sort.SortOption.priceHighToLow:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case sort.SortOption.newest:
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case sort.SortOption.rating:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case sort.SortOption.popularity:
      case sort.SortOption.bestSelling:
        // Implement based on your popularity/sales tracking
        break;
    }
    return products;
  }
}
