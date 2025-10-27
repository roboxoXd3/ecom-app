import 'package:get/get.dart';
import '../../data/models/vendor_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/vendor_repository.dart';

class VendorController extends GetxController {
  final VendorRepository _vendorRepository = VendorRepository();

  // Observable variables
  final RxList<Vendor> vendors = <Vendor>[].obs;
  final RxList<Vendor> featuredVendors = <Vendor>[].obs;
  final RxList<Vendor> followedVendors = <Vendor>[].obs;
  final RxList<Product> vendorProducts = <Product>[].obs;
  final Rx<Vendor?> currentUserVendor = Rx<Vendor?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isCurrentUserVendor = false.obs;
  final RxMap<String, bool> followStatus = <String, bool>{}.obs;
  final RxMap<String, int> followerCounts = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVendors();
    fetchFeaturedVendors();
    checkCurrentUserVendorStatus();
    fetchFollowedVendors();
  }

  /// Fetch all approved vendors
  Future<void> fetchVendors() async {
    try {
      isLoading.value = true;
      final fetchedVendors = await _vendorRepository.getApprovedVendors();
      vendors.value = fetchedVendors;
      print('📦 VendorController: Fetched ${fetchedVendors.length} vendors');
      if (fetchedVendors.isNotEmpty) {
        print('📦 First vendor: ${fetchedVendors.first.businessName}');
      }
    } catch (e) {
      print('❌ Error fetching vendors: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch vendors',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch featured vendors
  Future<void> fetchFeaturedVendors() async {
    try {
      final fetchedVendors = await _vendorRepository.getFeaturedVendors();
      featuredVendors.value = fetchedVendors;
    } catch (e) {
      print('Error fetching featured vendors: $e');
    }
  }

  /// Get vendor by ID
  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      return await _vendorRepository.getVendorById(vendorId);
    } catch (e) {
      print('Error fetching vendor by ID: $e');
      return null;
    }
  }

  /// Search vendors
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      return await _vendorRepository.searchVendors(query);
    } catch (e) {
      print('Error searching vendors: $e');
      return [];
    }
  }

  /// Register current user as vendor
  Future<bool> registerAsVendor({
    required String businessName,
    required String businessEmail,
    String? businessDescription,
    String? businessPhone,
    String? businessAddress,
  }) async {
    try {
      isLoading.value = true;

      final vendor = await _vendorRepository.registerAsVendor(
        businessName: businessName,
        businessEmail: businessEmail,
        businessDescription: businessDescription,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
      );

      if (vendor != null) {
        currentUserVendor.value = vendor;
        isCurrentUserVendor.value = vendor.isApproved;

        Get.snackbar(
          'Success',
          'Vendor registration submitted! You will be notified once approved.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error registering as vendor: $e');
      Get.snackbar(
        'Error',
        'Failed to register as vendor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if current user is a vendor
  Future<void> checkCurrentUserVendorStatus() async {
    try {
      final vendor = await _vendorRepository.getCurrentUserVendor();
      currentUserVendor.value = vendor;
      isCurrentUserVendor.value = vendor != null && vendor.isApproved;
    } catch (e) {
      print('Error checking vendor status: $e');
    }
  }

  /// Get current user's vendor profile
  Future<void> fetchCurrentUserVendor() async {
    try {
      final vendor = await _vendorRepository.getCurrentUserVendor();
      currentUserVendor.value = vendor;
    } catch (e) {
      print('Error fetching current user vendor: $e');
    }
  }

  /// Update vendor profile
  Future<bool> updateVendorProfile({
    required String vendorId,
    String? businessName,
    String? businessDescription,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessLogo,
  }) async {
    try {
      isLoading.value = true;

      final updatedVendor = await _vendorRepository.updateVendor(
        vendorId: vendorId,
        businessName: businessName,
        businessDescription: businessDescription,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        businessAddress: businessAddress,
        businessLogo: businessLogo,
      );

      if (updatedVendor != null) {
        currentUserVendor.value = updatedVendor;

        // Update in vendors list if exists
        final index = vendors.indexWhere((v) => v.id == vendorId);
        if (index != -1) {
          vendors[index] = updatedVendor;
        }

        Get.snackbar(
          'Success',
          'Vendor profile updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating vendor profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update vendor profile',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh all vendor data
  Future<void> refreshVendorData() async {
    await Future.wait([
      fetchVendors(),
      fetchFeaturedVendors(),
      checkCurrentUserVendorStatus(),
    ]);
  }

  /// Fetch products for a specific vendor
  Future<void> fetchVendorProducts(String vendorId) async {
    try {
      isLoading.value = true;
      print('🔄 VendorController: Fetching products for vendor $vendorId');
      final products = await _vendorRepository.getVendorProducts(vendorId);
      vendorProducts.value = products;
      print(
        '✅ VendorController: Successfully loaded ${products.length} products for vendor $vendorId',
      );
    } catch (e) {
      print('❌ VendorController: Error fetching vendor products: $e');
      vendorProducts.clear();
      Get.snackbar(
        'Error',
        'Failed to load vendor products',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Follow a vendor
  Future<void> followVendor(String vendorId) async {
    try {
      final success = await _vendorRepository.followVendor(vendorId);
      if (success) {
        followStatus[vendorId] = true;

        // Update follower count
        final count = await _vendorRepository.getVendorFollowerCount(vendorId);
        followerCounts[vendorId] = count;

        // Refresh followed vendors list
        await fetchFollowedVendors();

        Get.snackbar(
          'Success',
          'You are now following this vendor!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error following vendor: $e');
      Get.snackbar(
        'Error',
        'Failed to follow vendor',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Unfollow a vendor
  Future<void> unfollowVendor(String vendorId) async {
    try {
      final success = await _vendorRepository.unfollowVendor(vendorId);
      if (success) {
        followStatus[vendorId] = false;

        // Update follower count
        final count = await _vendorRepository.getVendorFollowerCount(vendorId);
        followerCounts[vendorId] = count;

        // Refresh followed vendors list
        await fetchFollowedVendors();

        Get.snackbar(
          'Success',
          'You have unfollowed this vendor',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error unfollowing vendor: $e');
      Get.snackbar(
        'Error',
        'Failed to unfollow vendor',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Toggle follow status for a vendor
  Future<void> toggleFollowVendor(String vendorId) async {
    final isFollowing = followStatus[vendorId] ?? false;
    if (isFollowing) {
      await unfollowVendor(vendorId);
    } else {
      await followVendor(vendorId);
    }
  }

  /// Check if user is following a vendor
  Future<void> checkFollowStatus(String vendorId) async {
    try {
      final isFollowing = await _vendorRepository.isFollowingVendor(vendorId);
      followStatus[vendorId] = isFollowing;
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  /// Get follower count for a vendor
  Future<void> fetchFollowerCount(String vendorId) async {
    try {
      final count = await _vendorRepository.getVendorFollowerCount(vendorId);
      followerCounts[vendorId] = count;
    } catch (e) {
      print('Error fetching follower count: $e');
    }
  }

  /// Fetch all vendors that current user is following
  Future<void> fetchFollowedVendors() async {
    try {
      final vendors = await _vendorRepository.getFollowedVendors();
      followedVendors.value = vendors;

      // Update follow status for all followed vendors
      for (final vendor in vendors) {
        followStatus[vendor.id] = true;
      }
    } catch (e) {
      print('Error fetching followed vendors: $e');
    }
  }

  /// Check if vendor is followed by current user
  bool isVendorFollowed(String vendorId) {
    return followStatus[vendorId] ?? false;
  }

  /// Get follower count for a vendor (from cache or 0)
  int getFollowerCount(String vendorId) {
    return followerCounts[vendorId] ?? 0;
  }

  /// Initialize vendor follow data (call when viewing vendor profile)
  Future<void> initializeVendorData(String vendorId) async {
    await Future.wait([
      checkFollowStatus(vendorId),
      fetchFollowerCount(vendorId),
    ]);
  }
}
