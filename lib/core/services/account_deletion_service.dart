import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for account deletion operations
class DeleteAccountResult {
  final bool success;
  final String message;
  final String? errorCode;
  final bool isVendor;

  DeleteAccountResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.isVendor = false,
  });

  factory DeleteAccountResult.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      errorCode: json['error'],
      isVendor: json['isVendor'] ?? false,
    );
  }
}

/// Service class for handling account deletion operations
/// Implements Google Play Store compliant account deletion
class AccountDeletionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if the current user can delete their account
  /// Returns true if user is NOT an active vendor
  static Future<DeleteAccountResult> checkDeletionEligibility() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        return DeleteAccountResult(
          success: false,
          message: 'User not authenticated. Please log in to continue.',
          errorCode: 'not_authenticated',
        );
      }

      // Call the is_active_vendor function
      final response = await _supabase
          .rpc('is_active_vendor', params: {'user_uuid': user.id});

      final bool isVendor = response as bool;

      if (isVendor) {
        return DeleteAccountResult(
          success: false,
          message:
              'Cannot delete account while you have an active vendor account. '
              'Please contact support to close your vendor account first.',
          errorCode: 'vendor_active',
          isVendor: true,
        );
      }

      return DeleteAccountResult(
        success: true,
        message: 'Your account is eligible for deletion.',
        isVendor: false,
      );
    } on PostgrestException catch (e) {
      print('Supabase error checking deletion eligibility: ${e.message}');
      return DeleteAccountResult(
        success: false,
        message: 'Failed to check account eligibility: ${e.message}',
        errorCode: 'database_error',
      );
    } catch (e) {
      print('Error checking deletion eligibility: $e');
      return DeleteAccountResult(
        success: false,
        message:
            'An unexpected error occurred while checking account eligibility.',
        errorCode: 'unknown_error',
      );
    }
  }

  /// Delete the current user's account
  /// This will:
  /// - Delete all personal information
  /// - Anonymize order history (for legal compliance)
  /// - Remove the user from authentication system
  /// 
  /// Requires: User must be authenticated and not an active vendor
  static Future<DeleteAccountResult> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return DeleteAccountResult(
          success: false,
          message: 'User not authenticated. Please log in to continue.',
          errorCode: 'not_authenticated',
        );
      }

      print('🗑️ Starting account deletion for user: ${user.id}');

      // Call the delete_user_account function
      final response = await _supabase
          .rpc('delete_user_account', params: {'user_uuid': user.id});

      print('🗑️ Deletion response: $response');

      // Parse the response
      if (response == null) {
        return DeleteAccountResult(
          success: false,
          message: 'Failed to delete account. Please try again or contact support.',
          errorCode: 'no_response',
        );
      }

      final Map<String, dynamic> result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        print('✅ Account data deleted successfully');
        
        // Sign out the user
        await _supabase.auth.signOut();
        print('✅ User signed out');

        return DeleteAccountResult(
          success: true,
          message: result['message'] ??
              'Your account has been successfully deleted. '
              'All personal information has been removed.',
        );
      } else {
        // Handle error cases
        final errorCode = result['error'] ?? 'deletion_failed';
        final errorMessage = result['message'] ?? 'Account deletion failed';

        print('❌ Account deletion failed: $errorCode - $errorMessage');

        return DeleteAccountResult(
          success: false,
          message: errorMessage,
          errorCode: errorCode,
          isVendor: errorCode == 'vendor_active',
        );
      }
    } on PostgrestException catch (e) {
      print('❌ Supabase error during account deletion: ${e.message}');
      return DeleteAccountResult(
        success: false,
        message: 'Database error: ${e.message}',
        errorCode: 'database_error',
      );
    } on AuthException catch (e) {
      print('❌ Auth error during account deletion: ${e.message}');
      return DeleteAccountResult(
        success: false,
        message: 'Authentication error: ${e.message}',
        errorCode: 'auth_error',
      );
    } catch (e) {
      print('❌ Unexpected error during account deletion: $e');
      return DeleteAccountResult(
        success: false,
        message:
            'An unexpected error occurred while deleting your account. '
            'Please try again or contact support.',
        errorCode: 'unknown_error',
      );
    }
  }

  /// Verify user password before allowing deletion
  /// This adds an extra layer of security
  static Future<bool> verifyPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null || user.email == null) {
        return false;
      }

      // Try to sign in with the provided password
      final response = await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      return response.user != null;
    } on AuthException catch (e) {
      print('Password verification failed: ${e.message}');
      return false;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  /// Get information about what data will be deleted and what will be retained
  static Map<String, List<String>> getDeletionInfo() {
    return {
      'deleted': [
        'Personal information (name, phone number, profile picture)',
        'Shipping addresses',
        'Payment methods',
        'Wishlist items',
        'Shopping cart',
        'Chat messages and conversations',
        'Search history',
        'Loyalty points and rewards',
        'Currency preferences',
        'Account credentials',
      ],
      'anonymized': [
        'Order history (anonymized for legal and tax compliance)',
        'Order details will show "Deleted User" instead of your information',
      ],
    };
  }
}

