import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';

// Import the extracted widgets
import 'widgets/category_header.dart';
import 'widgets/search_dialog.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/category_products_grid.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final Category category;
  final productController = Get.find<ProductController>();

  // Add search and filter state
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;
  final RxList<String> selectedBrands = <String>[].obs;
  final RxDouble minRating = 0.0.obs;
  final RxBool showOnSaleOnly = false.obs;
  final RxBool showInStockOnly = false.obs;
  final RxString sortBy = 'newest'.obs;

  CategoryDetailsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Category Header with SliverAppBar
          CategoryHeader(
            category: category,
            productController: productController,
            onSearchTap: () => _showSearchDialog(context),
          ),

          // Category Info Section
          CategoryInfoSection(
            category: category,
            productController: productController,
          ),

          // Products Section Header
          ProductsHeader(onFilterTap: () => _showFilterBottomSheet(context)),

          // Products Grid
          CategoryProductsGrid(
            category: category,
            productController: productController,
            searchQuery: searchQuery,
            applyFilters: _applyFilters,
            applySorting: _applySorting,
            onClearFilters: () {
              searchQuery.value = '';
              _resetFilters();
            },
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    SearchDialog.show(context, category, searchQuery);
  }

  void _showFilterBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    FilterBottomSheet.show(
      context,
      category,
      productController,
      minPrice,
      maxPrice,
      selectedBrands,
      minRating,
      showOnSaleOnly,
      showInStockOnly,
      sortBy,
      _resetFilters,
    );
  }

  List<Product> _applyFilters(List<Product> products) {
    return products.where((product) {
      // Price filter
      if (product.price < minPrice.value || product.price > maxPrice.value) {
        return false;
      }

      // Brand filter
      if (selectedBrands.isNotEmpty &&
          !selectedBrands.contains(product.brand)) {
        return false;
      }

      // Rating filter
      if (product.rating < minRating.value) {
        return false;
      }

      // On sale filter
      if (showOnSaleOnly.value && !product.isOnSale) {
        return false;
      }

      // In stock filter
      if (showInStockOnly.value && !product.inStock) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Product> _applySorting(List<Product> products) {
    switch (sortBy.value) {
      case 'price_low_high':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'newest':
      default:
        // Assuming products have a createdAt field or similar
        // products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return products;
  }

  void _resetFilters() {
    searchQuery.value = '';
    selectedBrands.clear();
    minRating.value = 0.0;
    showOnSaleOnly.value = false;
    showInStockOnly.value = false;
    sortBy.value = 'newest';

    // Reset price range to full range
    final categoryProducts =
        productController.allProducts
            .where((product) => product.categoryId == category.id)
            .toList();

    if (categoryProducts.isNotEmpty) {
      final prices = categoryProducts.map((p) => p.price).toList();
      minPrice.value = prices.reduce((a, b) => a < b ? a : b);
      maxPrice.value = prices.reduce((a, b) => a > b ? a : b);
    }
  }
}
