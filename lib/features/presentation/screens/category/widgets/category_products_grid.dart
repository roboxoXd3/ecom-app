import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import 'product_card.dart';
import '../../../../../core/theme/app_theme.dart';

class CategoryProductsGrid extends StatelessWidget {
  final Category category;
  final ProductController productController;
  final RxString searchQuery;
  final List<Product> Function(List<Product>) applyFilters;
  final List<Product> Function(List<Product>) applySorting;
  final VoidCallback onClearFilters;

  const CategoryProductsGrid({
    super.key,
    required this.category,
    required this.productController,
    required this.searchQuery,
    required this.applyFilters,
    required this.applySorting,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var products =
          productController.allProducts
              .where((product) => product.categoryId == category.id)
              .toList();

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        products =
            products
                .where(
                  (product) => product.name.toLowerCase().contains(
                    searchQuery.value.toLowerCase(),
                  ),
                )
                .toList();
      }

      // Apply filters
      products = applyFilters(products);

      // Apply sorting
      products = applySorting(products);

      if (productController.isLoading.value) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading products...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (products.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust content based on available space
                final availableHeight = constraints.maxHeight;
                final isCompact = availableHeight < 200;

                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: availableHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isCompact ? 80 : 120,
                              height: isCompact ? 80 : 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 40 : 60,
                                ),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: isCompact ? 40 : 60,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: isCompact ? 12 : 24),
                            Flexible(
                              child: Text(
                                searchQuery.value.isNotEmpty
                                    ? 'No products found for "${searchQuery.value}"'
                                    : 'No products found',
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: isCompact ? 4 : 8),
                            Flexible(
                              child: Text(
                                searchQuery.value.isNotEmpty
                                    ? 'Try adjusting your search or filters.'
                                    : 'This category doesn\'t have any products yet.',
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 16,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (searchQuery.value.isNotEmpty && !isCompact) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: onClearFilters,
                                child: const Text('Clear Search & Filters'),
                              ),
                            ],
                            if (searchQuery.value.isNotEmpty && isCompact) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: onClearFilters,
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 100)),
              child: ProductCard(product: product, index: index),
            );
          }, childCount: products.length),
        ),
      );
    });
  }
}

class ProductsHeader extends StatelessWidget {
  final VoidCallback onFilterTap;

  const ProductsHeader({super.key, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeInUp(
        duration: const Duration(milliseconds: 700),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
