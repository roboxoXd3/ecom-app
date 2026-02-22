import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/subcategory_controller.dart';

// Import the extracted widgets
import 'widgets/category_header.dart';
import 'widgets/search_dialog.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/category_products_grid.dart';
import 'widgets/subcategory_chips.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  late final ProductController productController;
  late final SubcategoryController subcategoryController;

  // Add search and filter state
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = double.infinity.obs;
  final RxList<String> selectedBrands = <String>[].obs;
  final RxDouble minRating = 0.0.obs;
  final RxBool showOnSaleOnly = false.obs;
  final RxBool showInStockOnly = false.obs;
  final RxString sortBy = 'newest'.obs;

  // NEW: Subcategory filtering state
  final RxList<String> selectedSubcategoryIds = <String>[].obs;

  @override
  void initState() {
    super.initState();
    productController = Get.find<ProductController>();
    subcategoryController = Get.put(SubcategoryController());
    
    // Initialize subcategory selection - select all by default
    ever(subcategoryController.subcategories, (subcategories) {
      final categorySubcategories = subcategoryController
          .getSubcategoriesForCategory(widget.category.id);
      if (categorySubcategories.isNotEmpty && selectedSubcategoryIds.isEmpty) {
        selectedSubcategoryIds.addAll(categorySubcategories.map((s) => s.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Category Header with SliverAppBar
          CategoryHeader(
            category: widget.category,
            productController: productController,
            onSearchTap: () => _showSearchDialog(context),
          ),

          // Category Info Section
          CategoryInfoSection(
            category: widget.category,
            productController: productController,
          ),

          // NEW: Subcategory Chips Section
          SliverToBoxAdapter(
            child: SubcategoryChips(
              categoryId: widget.category.id,
              selectedSubcategoryIds: selectedSubcategoryIds,
              onSelectionChanged: (selectedIds) {
                selectedSubcategoryIds.assignAll(selectedIds);
              },
            ),
          ),

          // Products Section Header
          ProductsHeader(onFilterTap: () => _showFilterBottomSheet(context)),

          // Products Grid
          CategoryProductsGrid(
            category: widget.category,
            productController: productController,
            searchQuery: searchQuery,
            applyFilters: _applyFilters,
            applySorting: _applySorting,
            onClearFilters: () {
              searchQuery.value = '';
              _resetFilters();
              // Reset subcategory selection to all selected
              final categorySubcategories = subcategoryController
                  .getSubcategoriesForCategory(widget.category.id);
              selectedSubcategoryIds.assignAll(
                categorySubcategories.map((s) => s.id),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    SearchDialog.show(context, widget.category, searchQuery);
  }

  void _showFilterBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    FilterBottomSheet.show(
      context,
      widget.category,
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
      // NEW: Subcategory filter
      if (selectedSubcategoryIds.isNotEmpty &&
          product.subcategoryId != null &&
          !selectedSubcategoryIds.contains(product.subcategoryId!)) {
        return false;
      }

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

    // Reset subcategory selection to all selected
    final categorySubcategories = subcategoryController
        .getSubcategoriesForCategory(widget.category.id);
    selectedSubcategoryIds.assignAll(categorySubcategories.map((s) => s.id));

    // Reset price range to full range
    final categoryProducts =
        productController.allProducts
            .where((product) => product.categoryId == widget.category.id)
            .toList();

    if (categoryProducts.isNotEmpty) {
      final prices = categoryProducts.map((p) => p.price).toList();
      minPrice.value = prices.reduce((a, b) => a < b ? a : b);
      maxPrice.value = prices.reduce((a, b) => a > b ? a : b);
    } else {
      minPrice.value = 0.0;
      maxPrice.value = double.infinity;
    }
  }
}
