import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/vendor_controller.dart';
import '../../../data/models/vendor_model.dart';
import 'vendor_profile_screen.dart';
import 'vendors_list_screen.dart';

class FollowedVendorsScreen extends StatelessWidget {
  const FollowedVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VendorController vendorController = Get.find<VendorController>();

    // Refresh followed vendors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vendorController.fetchFollowedVendors();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Followed Vendors'), elevation: 0),
      body: Obx(() {
        if (vendorController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vendorController.followedVendors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Followed Vendors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start following vendors to see them here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.off(() => const VendorsListScreen()),
                  child: const Text('Explore Vendors'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vendorController.fetchFollowedVendors(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vendorController.followedVendors.length,
            itemBuilder: (context, index) {
              final vendor = vendorController.followedVendors[index];
              return _buildVendorCard(vendor, vendorController);
            },
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
                    Text(
                      vendor.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

              // Follow Status & Actions
              Column(
                children: [
                  Obx(() {
                    final followerCount = vendorController.getFollowerCount(
                      vendor.id,
                    );
                    return Text(
                      '$followerCount followers',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    );
                  }),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Following',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
