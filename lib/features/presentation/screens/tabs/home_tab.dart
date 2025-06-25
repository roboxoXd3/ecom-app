import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';

import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../product/product_details_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/notification_controller.dart';
import '../product/product_list_screen.dart';
import '../category/category_details_screen.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/home_controller.dart';
import '../chat/chatbot_screen.dart';

class HomeTab extends StatelessWidget {
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>();

  final List<Map<String, dynamic>> banners = [
    {
      'image': 'assets/images/carousel/summer_sale.jpeg',
      'title': 'Summer Sale',
      'subtitle': 'Up to 50% OFF',
    },
    {
      'image': 'assets/images/carousel/new_collection.jpeg',
      'title': 'New Collection',
      'subtitle': 'Spring 2024',
    },
    {
      'image': 'assets/images/carousel/premium_collection.jpeg',
      'title': 'Premium Collection',
      'subtitle': 'Luxury Brands',
    },
  ];

  HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => productController.refreshProducts(),
          color: AppTheme.primaryColor,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Consistent top spacing
              const SizedBox(height: 8),

              // Hero Carousel Section
              _buildHeroCarousel(screenWidth),

              // Categories Section
              _buildCategoriesSection(screenWidth),

              // New Arrivals Section
              _buildNewArrivalsSection(screenWidth),

              // Chatbot Promotion Section
              _buildChatbotSection(),

              // Featured Products Section
              _buildFeaturedProductsSection(screenWidth),

              // Bottom spacing for FAB
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          'assets/images/logo.png',
          height: 32,
          width: 32,
          fit: BoxFit.contain,
        ),
      ),
      title: const Text(
        'Be Smart Mall',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          iconSize: 24,
          onPressed: () => Get.to(() => const SearchScreen()),
          tooltip: 'Search',
        ),
        _buildNotificationButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 24,
          onPressed: () => Get.to(() => const NotificationsScreen()),
          tooltip: 'Notifications',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Obx(() {
            final count = notificationController.unreadCount.value;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroCarousel(double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: CarouselSlider(
        options: CarouselOptions(
          height: screenWidth * 0.5, // Responsive height
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 2.0,
          autoPlayCurve: Curves.easeInOutCubic,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
          viewportFraction: 0.9,
          autoPlayInterval: const Duration(seconds: 4),
        ),
        items:
            banners.map((banner) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: screenWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            banner['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.grey200,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: AppTheme.grey400,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Gradient overlay for better text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          // Text overlay
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner['subtitle'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(44, 44), // Accessibility
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(double screenWidth) {
    return Column(
      children: [
        _buildSectionHeader('Categories', () {
          final homeController = Get.find<HomeController>();
          homeController.changeTab(1);
        }),
        const SizedBox(height: 16),
        Obx(() {
          if (categoryController.isLoading.value) {
            return SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            );
          }

          final displayCategories =
              categoryController.categories.take(5).toList();

          return SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final category = displayCategories[index];

                // Map category names to local icons for better UI
                final iconMap = {
                  'men': 'assets/images/category/men.jpeg',
                  'women': 'assets/images/category/women.jpeg',
                  'kids': 'assets/images/category/kids.jpeg',
                  'accessories': 'assets/images/category/accessories.jpeg',
                  'shoes': 'assets/images/category/shoes.jpeg',
                  'electronics': 'assets/images/category/electronics.jpeg',
                  'beauty': 'assets/images/category/beauty.jpeg',
                  'sports': 'assets/images/category/sports.jpeg',
                };

                final iconPath =
                    iconMap[category.name.toLowerCase()] ??
                    'assets/images/category/accessories.jpeg';

                return Container(
                  width: 90,
                  margin: EdgeInsets.only(
                    right: index == displayCategories.length - 1 ? 0 : 16,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigate to category details screen with real category
                        Get.to(() => CategoryDetailsScreen(category: category));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.grey100,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  iconPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category_outlined,
                                      size: 28,
                                      color: AppTheme.primaryColor,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNewArrivalsSection(double screenWidth) {
    return Column(
      children: [
        _buildSectionHeader('New Arrivals', () {
          Get.to(() => ProductListScreen(title: 'New Arrivals'));
        }),
        const SizedBox(height: 16),
        FutureBuilder<List<Product>>(
          future: productController.getNewArrivals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 280,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 280,
                child: Center(
                  child: Text(
                    'No new arrivals found',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final product = snapshot.data![index];
                  return Container(
                    width: screenWidth * 0.45, // Responsive width
                    margin: EdgeInsets.only(
                      right: index == snapshot.data!.length - 1 ? 0 : 16,
                    ),
                    child: _buildProductCard(product),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailsScreen(product: product)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.imageList.first,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: AppTheme.grey100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: AppTheme.grey100,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: AppTheme.grey400,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              // Product Info
              Container(
                height: 90, // Increased height for two-line text
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹${(product.isOnSale && product.salePrice != null ? product.salePrice! : product.price).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isOnSale &&
                            product.salePrice != null &&
                            product.salePrice! < product.price) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatbotSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => Get.to(
                () => ChatbotScreen(),
                transition: Transition.rightToLeft,
              ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withBlue(255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Need Help?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chat with our AI assistant for instant help with products, orders, and more!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 44,
                        child: ElevatedButton(
                          onPressed:
                              () => Get.to(
                                () => ChatbotScreen(),
                                transition: Transition.rightToLeft,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Start Chat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 40,
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
  }

  Widget _buildFeaturedProductsSection(double screenWidth) {
    return Column(
      children: [
        _buildSectionHeader('Featured Products', () {
          Get.to(() => ProductListScreen(title: 'Featured Products'));
        }),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 600 ? 3 : 2, // Responsive columns
              childAspectRatio: 0.75, // Adjusted for increased info height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount:
                productController.featuredProducts.length > 6
                    ? 6
                    : productController.featuredProducts.length,
            itemBuilder: (context, index) {
              final product = productController.featuredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }
}
