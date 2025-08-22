import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/enhanced_product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/reviews_controller.dart';
import '../../controllers/qa_controller.dart';
import '../../widgets/pdp/hero_gallery.dart';
import '../../widgets/pdp/enhanced_price_block.dart';
import '../../widgets/pdp/color_size_selection.dart';
import '../../widgets/pdp/feature_posters_carousel.dart';
import '../../widgets/pdp/promos_offers_row.dart';
import '../../widgets/pdp/delivery_estimator.dart';
import '../../widgets/pdp/key_highlights_strip.dart';
import '../../widgets/pdp/specifications_table.dart';
import '../../widgets/pdp/box_contents.dart';
import '../../widgets/pdp/usage_care_safety.dart';
import '../../widgets/pdp/warranty_returns.dart';
import '../../widgets/pdp/ratings_reviews.dart';
import '../../widgets/pdp/qa_section.dart';
import '../../widgets/pdp/recommendation_shelves.dart';
import '../../widgets/pdp/enhanced_sticky_cta.dart';

/// Real Enhanced Product Details Screen using database data
/// This replaces the mock data version with real Supabase integration
class RealEnhancedProductDetailsScreen extends StatefulWidget {
  final String productId;

  const RealEnhancedProductDetailsScreen({super.key, required this.productId});

  @override
  State<RealEnhancedProductDetailsScreen> createState() =>
      _RealEnhancedProductDetailsScreenState();
}

class _RealEnhancedProductDetailsScreenState
    extends State<RealEnhancedProductDetailsScreen> {
  final EnhancedProductController enhancedController =
      Get.find<EnhancedProductController>();
  final CartController cartController = Get.find<CartController>();
  final ProductController productController = Get.find<ProductController>();
  final ScrollController _scrollController = ScrollController();

  bool _showStickyCTA = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    Get.put(ReviewsController());
    Get.put(QAController());

    // Load enhanced product data
    enhancedController.loadEnhancedProduct(widget.productId);

    // Listen to scroll to show/hide sticky CTA
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show sticky CTA after scrolling past the price block (approximately 600px)
    final shouldShow = _scrollController.offset > 600;
    if (shouldShow != _showStickyCTA) {
      setState(() {
        _showStickyCTA = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        // Loading state
        if (enhancedController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        // Error state
        if (enhancedController.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enhancedController.error.value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => enhancedController.refreshProduct(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Product loaded successfully
        final product = enhancedController.product.value;
        if (product == null) {
          return const Center(child: Text('Product not found'));
        }

        // Product is already initialized in EnhancedProductController

        return Stack(
          children: [
            // Main content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Get.back(),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                    ),
                    Obx(
                      () => IconButton(
                        icon: Icon(
                          productController.wishlistProductIds.contains(
                                product.id,
                              )
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              productController.wishlistProductIds.contains(
                                    product.id,
                                  )
                                  ? Colors.red
                                  : Colors.black,
                        ),
                        onPressed:
                            () => productController.toggleWishlist(product),
                      ),
                    ),
                    Obx(
                      () => Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              // Navigate to home screen and switch to cart tab
                              Get.offAllNamed('/home');
                              final homeController = Get.find<HomeController>();
                              homeController.navigateToTab(
                                2,
                              ); // Cart tab is at index 2
                            },
                          ),
                          if (cartController.items.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${cartController.items.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main content
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero Gallery
                      HeroGallery(
                        images: enhancedController.currentImages,
                        onImageChanged: enhancedController.updateImageIndex,
                        videoUrl:
                            product.videoUrl, // Pass video URL to hero gallery
                        productName: product.name,
                      ),

                      // 2. Price Block
                      EnhancedPriceBlock(product: product),

                      // 3. Color & Size Selection (if available)
                      if (product.colors.isNotEmpty || product.sizes.isNotEmpty)
                        ColorSizeSelection(product: product),

                      // 4. Feature Posters Carousel (if available)
                      if (product.featurePosters.isNotEmpty)
                        FeaturePostersCarousel(posters: product.featurePosters),

                      // 5. Promos & Offers Row (if available)
                      if (product.offers.isNotEmpty)
                        PromosOffersRow(offers: product.offers),

                      // 6. Delivery Estimator
                      if (product.deliveryInfo != null)
                        DeliveryEstimator(deliveryInfo: product.deliveryInfo!),

                      // 7. Key Highlights Strip (if available)
                      if (product.highlights.isNotEmpty)
                        KeyHighlightsStrip(highlights: product.highlights),

                      // 8. Specifications Table (if available)
                      if (product.specifications.isNotEmpty)
                        SpecificationsTable(
                          specifications: product.specifications,
                        ),

                      // 9. Box Contents (if available)
                      if (product.boxContents.isNotEmpty)
                        BoxContents(contents: product.boxContents),

                      // 10. Usage, Care & Safety (if available)
                      if (product.usageInstructions.isNotEmpty ||
                          product.careInstructions.isNotEmpty ||
                          product.safetyNotes.isNotEmpty)
                        UsageCareSafety(
                          usageInstructions: product.usageInstructions,
                          careInstructions: product.careInstructions,
                          safetyNotes: product.safetyNotes,
                        ),

                      // 11. Warranty & Returns (if available)
                      if (product.warranty != null ||
                          product.deliveryInfo != null)
                        WarrantyReturns(
                          warranty: product.warranty,
                          deliveryInfo: product.deliveryInfo,
                        ),

                      // 12. Ratings & Reviews
                      RatingsReviews(product: product),

                      // 13. Q&A Section
                      QASection(productId: product.id),

                      // 14. Recommendation Shelves
                      RecommendationShelves(
                        recommendations: product.recommendations,
                        onProductTap: (productId) {
                          // Navigate to another product
                          Get.toNamed(
                            '/enhanced-product-details',
                            arguments: productId,
                          );
                        },
                      ),

                      // Bottom padding for sticky CTA
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),

            // Sticky CTA (Enhanced)
            if (_showStickyCTA)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EnhancedStickyCTA(
                  product: product,
                  isVisible: _showStickyCTA,
                ),
              ),
          ],
        );
      }),
    );
  }
}
