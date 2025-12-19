import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
// Add this import for ImageFilter
import '../../../../core/routes/app_routes.dart';
import '../../controllers/category_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();

    return Scaffold(
      backgroundColor: AppTheme.getSurface(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.getSurface(context),
            foregroundColor: AppTheme.getTextPrimary(context),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculate if the app bar is collapsed
                final bool isCollapsed =
                    constraints.biggest.height <=
                    kToolbarHeight + MediaQuery.of(context).padding.top;

                return FlexibleSpaceBar(
                  centerTitle: true,
                  title: FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Explore Categories',
                      style: TextStyle(
                        color:
                            isCollapsed
                                ? AppTheme.getTextPrimary(context)
                                : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: 0.5,
                        shadows:
                            isCollapsed
                                ? []
                                : [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                ],
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                          AppTheme.primaryVariant.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Subtle pattern overlay
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Floating circles for visual appeal
                        Positioned(
                          top: 20,
                          right: 30,
                          child: FadeInRight(
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: 40,
                          child: FadeInLeft(
                            duration: const Duration(milliseconds: 1000),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getBorder(
                          context,
                        ).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: TextStyle(
                        color: AppTheme.grey500,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.grey600,
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Categories Grid
          Obx(() {
            if (categoryController.isLoading.value) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                        'Loading categories...',
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = categoryController.categories[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    child: _buildModernCategoryCard(context, category, index),
                  );
                }, childCount: categoryController.categories.length),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernCategoryCard(BuildContext context, category, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getBorder(context).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.toNamed(
                AppRoutes.categoryDetails.replaceAll(':id', category.id),
                arguments: category,
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Full Background Image
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getCategoryColor(index).withOpacity(0.8),
                                  _getCategoryColor(index).withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getCategoryIcon(index),
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getCategoryColor(index).withOpacity(0.8),
                                  _getCategoryColor(index).withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getCategoryIcon(index),
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                    ),
                  ),

                  // Gradient Overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Content Overlay with Fixed Layout
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category Name with Fixed Height Container
                        Container(
                          height: 44, // Fixed height to prevent overflow
                          alignment: Alignment.center,
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Explore Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Explore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
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
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    return AppTheme.categoryColors[index % AppTheme.categoryColors.length];
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.checkroom_rounded, // Women's Clothing
      Icons.sports_soccer_rounded, // Sports
      Icons.man_rounded, // Men's Clothing
      Icons.devices_rounded, // Electronics
      Icons.home_rounded, // Home
      Icons.restaurant_rounded, // Food
      Icons.local_florist_rounded, // Beauty
      Icons.toys_rounded, // Toys
    ];
    return icons[index % icons.length];
  }
}
