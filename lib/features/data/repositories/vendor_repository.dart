import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import '../models/vendor_follow_model.dart';
import '../models/vendor_review_model.dart';

class VendorRepository {
  final _api = ApiClient.instance;

  Future<List<Vendor>> getApprovedVendors() async {
    try {
      final response = await _api.get('/vendors/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((v) => Vendor.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching approved vendors: $e');
      return [];
    }
  }

  Future<List<Vendor>> getFeaturedVendors() async {
    try {
      final response = await _api.get('/vendors/featured/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((v) => Vendor.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching featured vendors: $e');
      return [];
    }
  }

  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      final response = await _api.get('/vendors/$vendorId/');
      return Vendor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      print('Error fetching vendor by ID: $e');
      return null;
    } catch (e) {
      print('Error fetching vendor by ID: $e');
      return null;
    }
  }

  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final response = await _api.get('/vendors/search/', queryParameters: {
        'q': query,
      });
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((v) => Vendor.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching vendors: $e');
      return [];
    }
  }

  Future<Vendor?> registerAsVendor({
    required String businessName,
    required String businessEmail,
    String? businessDescription,
    String? businessPhone,
    String? businessAddress,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User must be authenticated to register as vendor');
      }

      final response = await _api.post('/vendors/', data: {
        'business_name': businessName,
        'business_email': businessEmail,
        if (businessDescription != null)
          'business_description': businessDescription,
        if (businessPhone != null) 'business_phone': businessPhone,
        if (businessAddress != null) 'business_address': businessAddress,
      });

      return Vendor.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error registering as vendor: $e');
      rethrow;
    }
  }

  Future<Vendor?> getCurrentUserVendor() async {
    try {
      if (!AuthService.isAuthenticated()) return null;
      final response = await _api.get('/vendors/me/');
      return Vendor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      print('Error fetching current user vendor: $e');
      return null;
    } catch (e) {
      print('Error fetching current user vendor: $e');
      return null;
    }
  }

  Future<bool> isCurrentUserVendor() async {
    final vendor = await getCurrentUserVendor();
    return vendor != null && vendor.isApproved;
  }

  Future<Vendor?> updateVendor({
    required String vendorId,
    String? businessName,
    String? businessDescription,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessLogo,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (businessName != null) updateData['business_name'] = businessName;
      if (businessDescription != null) {
        updateData['business_description'] = businessDescription;
      }
      if (businessEmail != null) updateData['business_email'] = businessEmail;
      if (businessPhone != null) updateData['business_phone'] = businessPhone;
      if (businessAddress != null) {
        updateData['business_address'] = businessAddress;
      }
      if (businessLogo != null) updateData['business_logo'] = businessLogo;

      if (updateData.isEmpty) return null;

      final response = await _api.patch('/vendors/$vendorId/', data: updateData);
      return Vendor.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error updating vendor: $e');
      rethrow;
    }
  }

  Future<List<Product>> getVendorProducts(String vendorId) async {
    try {
      final response = await _api.get('/vendors/$vendorId/products/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching vendor products: $e');
      return [];
    }
  }

  Future<bool> followVendor(String vendorId) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User must be authenticated to follow vendors');
      }
      await _api.post('/vendors/$vendorId/follow/');
      return true;
    } catch (e) {
      print('Error following vendor: $e');
      return false;
    }
  }

  Future<bool> unfollowVendor(String vendorId) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User must be authenticated to unfollow vendors');
      }
      await _api.delete('/vendors/$vendorId/follow/');
      return true;
    } catch (e) {
      print('Error unfollowing vendor: $e');
      return false;
    }
  }

  Future<bool> isFollowingVendor(String vendorId) async {
    try {
      if (!AuthService.isAuthenticated()) return false;
      final response = await _api.get('/vendors/$vendorId/follow/');
      final data = response.data as Map<String, dynamic>;
      return data['is_following'] == true;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  Future<List<Vendor>> getFollowedVendors() async {
    try {
      if (!AuthService.isAuthenticated()) return [];
      final response = await _api.get('/vendors/following/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((v) => Vendor.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching followed vendors: $e');
      return [];
    }
  }

  Future<int> getVendorFollowerCount(String vendorId) async {
    try {
      final response = await _api.get('/vendors/$vendorId/followers/');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['count'] ?? data['follower_count'] ?? 0;
      }
      if (data is List) return data.length;
      return 0;
    } catch (e) {
      print('Error getting vendor follower count: $e');
      return 0;
    }
  }

  Future<List<VendorFollow>> getVendorFollowers(String vendorId) async {
    try {
      final response = await _api.get('/vendors/$vendorId/followers/');
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((f) => VendorFollow.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching vendor followers: $e');
      return [];
    }
  }

  Future<bool> addVendorReview({
    required String vendorId,
    required double rating,
    String? reviewText,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User must be authenticated to add reviews');
      }
      await _api.post('/vendors/$vendorId/reviews/', data: {
        'rating': rating,
        if (reviewText != null) 'review_text': reviewText,
      });
      return true;
    } catch (e) {
      print('Error adding vendor review: $e');
      return false;
    }
  }

  Future<bool> updateVendorReview({
    required String reviewId,
    required double rating,
    String? reviewText,
  }) async {
    try {
      await _api.patch('/vendors/reviews/$reviewId/', data: {
        'rating': rating,
        if (reviewText != null) 'review_text': reviewText,
      });
      return true;
    } catch (e) {
      print('Error updating vendor review: $e');
      return false;
    }
  }

  Future<bool> deleteVendorReview(String reviewId) async {
    try {
      await _api.delete('/vendors/reviews/$reviewId/');
      return true;
    } catch (e) {
      print('Error deleting vendor review: $e');
      return false;
    }
  }

  Future<List<VendorReview>> getVendorReviews(
    String vendorId, {
    int limit = 20,
  }) async {
    try {
      final response = await _api.get('/vendors/$vendorId/reviews/',
          queryParameters: {'limit': limit});
      final results = ApiClient.unwrapResults(response.data);
      return results
          .map((r) => VendorReview.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching vendor reviews: $e');
      return [];
    }
  }

  Future<VendorReview?> getUserReviewForVendor(String vendorId) async {
    try {
      if (!AuthService.isAuthenticated()) return null;
      final response = await _api.get('/vendors/$vendorId/my-review/');
      return VendorReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      print('Error fetching user vendor review: $e');
      return null;
    } catch (e) {
      print('Error fetching user vendor review: $e');
      return null;
    }
  }

  Future<bool> hasUserReviewedVendor(String vendorId) async {
    final review = await getUserReviewForVendor(vendorId);
    return review != null;
  }
}
