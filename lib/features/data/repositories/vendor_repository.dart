import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import '../models/vendor_follow_model.dart';
import '../models/vendor_review_model.dart';

class VendorRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all approved vendors
  Future<List<Vendor>> getApprovedVendors() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('status', 'approved')
          .order('business_name');

      return (response as List)
          .map((vendor) => Vendor.fromJson(vendor))
          .toList();
    } catch (e) {
      print('Error fetching approved vendors: $e');
      return [];
    }
  }

  /// Get featured vendors
  Future<List<Vendor>> getFeaturedVendors() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('status', 'approved')
          .eq('is_featured', true)
          .order('business_name');

      return (response as List)
          .map((vendor) => Vendor.fromJson(vendor))
          .toList();
    } catch (e) {
      print('Error fetching featured vendors: $e');
      return [];
    }
  }

  /// Get vendor by ID
  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      final response =
          await _supabase
              .from('vendors')
              .select('*')
              .eq('id', vendorId)
              .eq('status', 'approved')
              .maybeSingle();

      if (response != null) {
        return Vendor.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching vendor by ID: $e');
      return null;
    }
  }

  /// Search vendors by business name
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('status', 'approved')
          .ilike('business_name', '%$query%')
          .order('business_name');

      return (response as List)
          .map((vendor) => Vendor.fromJson(vendor))
          .toList();
    } catch (e) {
      print('Error searching vendors: $e');
      return [];
    }
  }

  /// Register as vendor (for authenticated users)
  Future<Vendor?> registerAsVendor({
    required String businessName,
    required String businessEmail,
    String? businessDescription,
    String? businessPhone,
    String? businessAddress,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to register as vendor');
      }

      final response =
          await _supabase
              .from('vendors')
              .insert({
                'user_id': user.id,
                'business_name': businessName,
                'business_email': businessEmail,
                'business_description': businessDescription,
                'business_phone': businessPhone,
                'business_address': businessAddress,
                'status': 'pending', // Will require admin approval
              })
              .select()
              .single();

      return Vendor.fromJson(response);
    } catch (e) {
      print('Error registering as vendor: $e');
      rethrow;
    }
  }

  /// Get current user's vendor profile
  Future<Vendor?> getCurrentUserVendor() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('vendors')
              .select('*')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        return Vendor.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching current user vendor: $e');
      return null;
    }
  }

  /// Check if current user is a vendor
  Future<bool> isCurrentUserVendor() async {
    final vendor = await getCurrentUserVendor();
    return vendor != null && vendor.isApproved;
  }

  /// Update vendor profile
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

      final response =
          await _supabase
              .from('vendors')
              .update(updateData)
              .eq('id', vendorId)
              .select()
              .single();

      return Vendor.fromJson(response);
    } catch (e) {
      print('Error updating vendor: $e');
      rethrow;
    }
  }

  /// Get all products from a specific vendor
  Future<List<Product>> getVendorProducts(String vendorId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, vendors(*), categories(*)')
          .eq('vendor_id', vendorId)
          .eq('in_stock', true)
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false);

      return (response as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } catch (e) {
      print('Error fetching vendor products: $e');
      return [];
    }
  }

  /// Follow a vendor
  Future<bool> followVendor(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to follow vendors');
      }

      await _supabase.from('vendor_follows').insert({
        'user_id': user.id,
        'vendor_id': vendorId,
      });

      return true;
    } catch (e) {
      print('Error following vendor: $e');
      return false;
    }
  }

  /// Unfollow a vendor
  Future<bool> unfollowVendor(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to unfollow vendors');
      }

      await _supabase
          .from('vendor_follows')
          .delete()
          .eq('user_id', user.id)
          .eq('vendor_id', vendorId);

      return true;
    } catch (e) {
      print('Error unfollowing vendor: $e');
      return false;
    }
  }

  /// Check if current user is following a vendor
  Future<bool> isFollowingVendor(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('vendor_follows')
              .select('id')
              .eq('user_id', user.id)
              .eq('vendor_id', vendorId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  /// Get all vendors that current user is following
  Future<List<Vendor>> getFollowedVendors() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('vendor_follows')
          .select('vendor_id, vendors(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .where((follow) => follow['vendors'] != null)
          .map(
            (follow) =>
                Vendor.fromJson(follow['vendors'] as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error fetching followed vendors: $e');
      return [];
    }
  }

  /// Get follower count for a vendor
  Future<int> getVendorFollowerCount(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendor_follows')
          .select('id')
          .eq('vendor_id', vendorId);

      return (response as List).length;
    } catch (e) {
      print('Error getting vendor follower count: $e');
      return 0;
    }
  }

  /// Get users following a vendor (for vendor dashboard)
  Future<List<VendorFollow>> getVendorFollowers(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendor_follows')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((follow) => VendorFollow.fromJson(follow))
          .toList();
    } catch (e) {
      print('Error fetching vendor followers: $e');
      return [];
    }
  }

  // NEW: Vendor Review Functionality

  /// Add a review for a vendor
  Future<bool> addVendorReview({
    required String vendorId,
    required double rating,
    String? reviewText,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to add reviews');
      }

      // Get user profile info for the review
      final userProfile =
          await _supabase
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('id', user.id)
              .maybeSingle();

      await _supabase.from('vendor_reviews').insert({
        'vendor_id': vendorId,
        'user_id': user.id,
        'user_name': userProfile?['full_name'] ?? 'Anonymous User',
        'user_avatar': userProfile?['avatar_url'],
        'rating': rating,
        'review_text': reviewText,
      });

      return true;
    } catch (e) {
      print('Error adding vendor review: $e');
      return false;
    }
  }

  /// Update a vendor review
  Future<bool> updateVendorReview({
    required String reviewId,
    required double rating,
    String? reviewText,
  }) async {
    try {
      await _supabase
          .from('vendor_reviews')
          .update({
            'rating': rating,
            'review_text': reviewText,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId);

      return true;
    } catch (e) {
      print('Error updating vendor review: $e');
      return false;
    }
  }

  /// Delete a vendor review
  Future<bool> deleteVendorReview(String reviewId) async {
    try {
      await _supabase.from('vendor_reviews').delete().eq('id', reviewId);

      return true;
    } catch (e) {
      print('Error deleting vendor review: $e');
      return false;
    }
  }

  /// Get reviews for a vendor
  Future<List<VendorReview>> getVendorReviews(
    String vendorId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('vendor_reviews')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((review) => VendorReview.fromJson(review))
          .toList();
    } catch (e) {
      print('Error fetching vendor reviews: $e');
      return [];
    }
  }

  /// Get user's review for a specific vendor
  Future<VendorReview?> getUserReviewForVendor(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('vendor_reviews')
              .select('*')
              .eq('vendor_id', vendorId)
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        return VendorReview.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching user vendor review: $e');
      return null;
    }
  }

  /// Check if user has reviewed a vendor
  Future<bool> hasUserReviewedVendor(String vendorId) async {
    final review = await getUserReviewForVendor(vendorId);
    return review != null;
  }
}
