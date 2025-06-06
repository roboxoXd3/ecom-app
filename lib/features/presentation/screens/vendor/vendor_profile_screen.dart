import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/vendor_controller.dart';
import '../../controllers/product_controller.dart';
import '../../../data/models/vendor_model.dart';
import '../../../data/models/product_model.dart';
import '../category/widgets/product_card.dart';
import '../product/product_details_screen.dart';

class VendorProfileScreen extends StatelessWidget {
  final Vendor vendor;

  const VendorProfileScreen({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final VendorController vendorController = Get.find<VendorController>();
    final ProductController productController = Get.find<ProductController>();

    // Fetch vendor's products and follow data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vendorController.fetchVendorProducts(vendor.id);
      vendorController.initializeVendorData(vendor.id);
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Vendor Cover
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                vendor.businessName,
                style: const TextStyle(
                  color: Colors.white,
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child:
                    vendor.businessLogo != null
                        ? CachedNetworkImage(
                          imageUrl: vendor.businessLogo!,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.3),
                          colorBlendMode: BlendMode.darken,
                        )
                        : Center(
                          child: Icon(
                            Icons.store,
                            size: 80,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Share vendor profile
                },
              ),
            ],
          ),

          // Vendor Information
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Rating',
                        vendor.averageRating.toStringAsFixed(1),
                        Icons.star,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        'Reviews',
                        vendor.totalReviews.toString(),
                        Icons.reviews,
                        AppTheme.primaryColor,
                      ),
                      Obx(
                        () => _buildStatCard(
                          'Products',
                          vendorController.vendorProducts.length.toString(),
                          Icons.inventory,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Vendor Description
                  if (vendor.businessDescription != null) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vendor.businessDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact Information
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (vendor.businessEmail.isNotEmpty)
                    _buildContactRow(Icons.email, vendor.businessEmail),

                  if (vendor.businessPhone != null)
                    _buildContactRow(Icons.phone, vendor.businessPhone!),

                  if (vendor.businessAddress != null)
                    _buildContactRow(
                      Icons.location_on,
                      vendor.businessAddress!,
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          final isFollowing = vendorController.isVendorFollowed(
                            vendor.id,
                          );
                          final followerCount = vendorController
                              .getFollowerCount(vendor.id);

                          return ElevatedButton.icon(
                            onPressed: () {
                              vendorController.toggleFollowVendor(vendor.id);
                            },
                            icon: Icon(
                              isFollowing
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            label: Text(
                              isFollowing
                                  ? 'Following ($followerCount)'
                                  : 'Follow ($followerCount)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFollowing
                                      ? Colors.grey[600]
                                      : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Contact vendor
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Products Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: View all products
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          Obx(() {
            if (vendorController.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (vendorController.vendorProducts.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No products available from this vendor'),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = vendorController.vendorProducts[index];
                  return ProductCard(product: product, index: index);
                }, childCount: vendorController.vendorProducts.length),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
