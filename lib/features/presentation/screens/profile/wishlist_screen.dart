import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/currency_controller.dart';

import 'package:cached_network_image/cached_network_image.dart';

enum WishlistSortOption { dateAdded, priceLowToHigh, priceHighToLow, name }

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ProductController productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();
  final CurrencyController currencyController = Get.find<CurrencyController>();

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rx<WishlistSortOption> currentSort = WishlistSortOption.dateAdded.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;
  final RxBool showFilters = false.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<dynamic> get filteredAndSortedProducts {
    var wishlistProducts =
        productController.allProducts
            .where(
              (product) =>
                  productController.wishlistProductIds.contains(product.id),
            )
            .toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      wishlistProducts =
          wishlistProducts
              .where(
                (product) => product.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply price filter
    wishlistProducts =
        wishlistProducts
            .where(
              (product) =>
                  product.price >= minPrice.value &&
                  product.price <= maxPrice.value,
            )
            .toList();

    // Apply sorting
    switch (currentSort.value) {
      case WishlistSortOption.priceLowToHigh:
        wishlistProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case WishlistSortOption.priceHighToLow:
        wishlistProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case WishlistSortOption.name:
        wishlistProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case WishlistSortOption.dateAdded:
      // Keep original order (most recently added first)
        break;
    }

    return wishlistProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          Obx(() {
            final wishlistCount = filteredAndSortedProducts.length;
            final totalCount =
                productController.allProducts
                    .where(
                      (product) => productController.wishlistProductIds
                          .contains(product.id),
                    )
                    .length;

            if (totalCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      searchQuery.value.isNotEmpty ||
                              minPrice.value > 0 ||
                              maxPrice.value < 1000
                          ? '$wishlistCount/$totalCount items'
                          : '$totalCount items',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return _buildSkeletonLoader();
              }

              final wishlistProducts = filteredAndSortedProducts;

              if (productController.allProducts
                  .where(
                    (product) => productController.wishlistProductIds.contains(
                      product.id,
                    ),
                  )
                  .isEmpty) {
                return _buildEmptyState(context);
              }

              if (wishlistProducts.isEmpty) {
                return _buildNoResultsState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await productController.refreshProducts();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = wishlistProducts[index];
                          return _buildProductCard(context, product, index);
                        }, childCount: wishlistProducts.length),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search your wishlist...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: Obx(
                  () =>
                      searchQuery.value.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                          )
                          : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter and Sort row
          Row(
            children: [
              Expanded(child: _buildSortButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildFilterButton()),
              const SizedBox(width: 12),
              _buildClearFiltersButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: _showSortOptions,
        icon: const Icon(Icons.sort, size: 18),
        label: Text(
          _getSortLabel(currentSort.value),
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Obx(() {
      final hasActiveFilters = minPrice.value > 0 || maxPrice.value < 1000;
      return OutlinedButton.icon(
        onPressed: _showFilterOptions,
        icon: Icon(
          Icons.filter_list,
          size: 18,
          color: hasActiveFilters ? Theme.of(context).primaryColor : null,
        ),
        label: Text(
          hasActiveFilters ? 'Filtered' : 'Filter',
          style: TextStyle(
            fontSize: 12,
            color: hasActiveFilters ? Theme.of(context).primaryColor : null,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color:
                hasActiveFilters
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }

  Widget _buildClearFiltersButton() {
    return Obx(() {
      final hasFilters =
          searchQuery.value.isNotEmpty ||
          minPrice.value > 0 ||
          maxPrice.value < 1000 ||
          currentSort.value != WishlistSortOption.dateAdded;

      if (!hasFilters) return const SizedBox.shrink();

      return IconButton(
        onPressed: _clearAllFilters,
        icon: Icon(Icons.clear_all, color: Colors.grey[600], size: 20),
        tooltip: 'Clear all filters',
      );
    });
  }

  String _getSortLabel(WishlistSortOption option) {
    switch (option) {
      case WishlistSortOption.dateAdded:
        return 'Recent';
      case WishlistSortOption.priceLowToHigh:
        return 'Price ↑';
      case WishlistSortOption.priceHighToLow:
        return 'Price ↓';
      case WishlistSortOption.name:
        return 'Name';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ...WishlistSortOption.values.map(
                  (option) => Obx(
                    () => ListTile(
                      title: Text(_getSortLabel(option)),
                      leading: Radio<WishlistSortOption>(
                        value: option,
                        groupValue: currentSort.value,
                        onChanged: (value) {
                          if (value != null) {
                            currentSort.value = value;
                            Navigator.pop(context);
                          }
                        },
                      ),
                      onTap: () {
                        currentSort.value = option;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Price',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => RangeSlider(
                    values: RangeValues(minPrice.value, maxPrice.value),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      '${currencyController.getCurrencySymbol(currencyController.selectedCurrency.value)}${minPrice.value.round()}',
                      '${currencyController.getCurrencySymbol(currencyController.selectedCurrency.value)}${maxPrice.value.round()}',
                    ),
                    onChanged: (values) {
                      minPrice.value = values.start;
                      maxPrice.value = values.end;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: ${currencyController.getCurrencySymbol(currencyController.selectedCurrency.value)}${minPrice.value.round()}',
                      ),
                      Text(
                        'Max: ${currencyController.getCurrencySymbol(currencyController.selectedCurrency.value)}${maxPrice.value.round()}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          minPrice.value = 0;
                          maxPrice.value = 1000;
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _clearAllFilters() {
    searchController.clear();
    searchQuery.value = '';
    minPrice.value = 0;
    maxPrice.value = 1000;
    currentSort.value = WishlistSortOption.dateAdded;
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 3;
    if (width > 400) return 2;
    return 2;
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add products you love to your wishlist\nand find them easily later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Dismissible(
            key: Key(product.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Remove from Wishlist'),
                      content: Text(
                        'Are you sure you want to remove "${product.name}" from your wishlist?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
              );
            },
            onDismissed: (direction) {
              productController.toggleWishlist(product);
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              child: InkWell(
                onTap:
                    () =>
                        Get.toNamed('/product-details', arguments: product.id),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'product-${product.id}',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    product.imageList.isNotEmpty
                                        ? product.imageList.first
                                        : '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[100],
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  productController.toggleWishlist(product);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(
                                () => Text(
                                  currencyController.getFormattedProductPrice(
                                    product.price,
                                    product.currency,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showQuickAddToCart(product),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_shopping_cart_outlined,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuickAddToCart(dynamic product) {
    if (product.sizeList.isEmpty || product.colorList.isEmpty) {
      // If no size or color options, add directly
      _addToCartDirectly(product);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => _QuickAddToCartSheet(
            product: product,
            onAddToCart: (size, color) {
              _addToCartWithOptions(product, size, color);
              Navigator.pop(context);
            },
          ),
    );
  }

  void _addToCartDirectly(dynamic product) {
    final defaultSize =
        product.sizeList.isNotEmpty ? product.sizeList.first : 'One Size';
    final defaultColor =
        product.colorList.isNotEmpty ? product.colorList.first : 'Default';

    _addToCartWithOptions(product, defaultSize, defaultColor);
  }

  void _addToCartWithOptions(dynamic product, String size, String color) async {
    try {
      await cartController.addToCart(product, size, color, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // Navigate to cart
              final homeController = Get.find();
              homeController.navigateToTab(2);
              Get.back();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to add to cart'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _QuickAddToCartSheet extends StatefulWidget {
  final dynamic product;
  final Function(String size, String color) onAddToCart;

  const _QuickAddToCartSheet({
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<_QuickAddToCartSheet> createState() => _QuickAddToCartSheetState();
}

class _QuickAddToCartSheetState extends State<_QuickAddToCartSheet> {
  String selectedSize = '';
  String selectedColor = '';

  @override
  void initState() {
    super.initState();
    if (widget.product.sizeList.isNotEmpty) {
      selectedSize = widget.product.sizeList.first;
    }
    if (widget.product.colorList.isNotEmpty) {
      selectedColor = widget.product.colorList.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      widget.product.imageList.isNotEmpty
                          ? widget.product.imageList.first
                          : '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    GetBuilder<CurrencyController>(
                      builder:
                          (currencyController) => Text(
                            currencyController.getFormattedProductPrice(
                              widget.product.price,
                              widget.product.currency,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.product.sizeList.isNotEmpty) ...[
            const Text(
              'Size',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.product.sizeList.map<Widget>((size) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedSize = size),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selectedSize == size
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedSize == size
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          size,
                          style: TextStyle(
                            color:
                                selectedSize == size
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.product.colorList.isNotEmpty) ...[
            const Text(
              'Color',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.product.colorList.map<Widget>((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selectedColor == color
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedColor == color
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          color,
                          style: TextStyle(
                            color:
                                selectedColor == color
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  selectedSize.isNotEmpty && selectedColor.isNotEmpty
                      ? () => widget.onAddToCart(selectedSize, selectedColor)
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
