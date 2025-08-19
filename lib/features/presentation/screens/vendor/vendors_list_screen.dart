import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/vendor_controller.dart';
import '../../../data/models/vendor_model.dart';
import 'vendor_profile_screen.dart';

class VendorsListScreen extends StatelessWidget {
  const VendorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VendorController vendorController = Get.find<VendorController>();

    // Refresh vendors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vendorController.fetchVendors();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vendors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vendorController.fetchVendors(),
          ),
        ],
      ),
      body: Obx(() {
        if (vendorController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vendorController.vendors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Vendors Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new vendors',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => vendorController.fetchVendors(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vendorController.fetchVendors(),
          child: Column(
            children: [
              // Header with count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${vendorController.vendors.length} Vendors Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Vendors list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vendorController.vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendorController.vendors[index];
                    return _buildVendorCard(vendor, vendorController);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVendorCard(Vendor vendor, VendorController vendorController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => VendorProfileScreen(vendor: vendor)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vendor Logo/Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child:
                    vendor.businessLogo != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            vendor.businessLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.store,
                                color: AppTheme.primaryColor,
                                size: 30,
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.store,
                          color: AppTheme.primaryColor,
                          size: 30,
                        ),
              ),
              const SizedBox(width: 16),

              // Vendor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vendor.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Featured',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (vendor.businessDescription != null)
                      Text(
                        vendor.businessDescription!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppTheme.ratingStars),
                        const SizedBox(width: 4),
                        Text(
                          vendor.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${vendor.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Follow Button & Actions
              Column(
                children: [
                  Obx(() {
                    final isFollowing =
                        vendorController.followStatus[vendor.id] ?? false;
                    return SizedBox(
                      width: 80,
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            () =>
                                vendorController.toggleFollowVendor(vendor.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isFollowing
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.primaryColor,
                          foregroundColor:
                              isFollowing
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side:
                                isFollowing
                                    ? BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 1,
                                    )
                                    : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Obx(() {
                    final followerCount = vendorController.getFollowerCount(
                      vendor.id,
                    );
                    return Text(
                      '$followerCount followers',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
