import '../network/api_client.dart';
import 'auth_service.dart';

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
  static final _api = ApiClient.instance;

  static Future<DeleteAccountResult> checkDeletionEligibility() async {
    try {
      if (!AuthService.isAuthenticated()) {
        return DeleteAccountResult(
          success: false,
          message: 'User not authenticated. Please log in to continue.',
          errorCode: 'not_authenticated',
        );
      }

      final response = await _api.get('/users/check-deletion-eligibility/');
      final data = response.data;

      if (data['is_vendor'] == true) {
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
    } catch (e) {
      print('Error checking deletion eligibility: $e');
      return DeleteAccountResult(
        success: false,
        message: 'An unexpected error occurred while checking account eligibility.',
        errorCode: 'unknown_error',
      );
    }
  }

  static Future<DeleteAccountResult> deleteAccount(String password) async {
    try {
      if (!AuthService.isAuthenticated()) {
        return DeleteAccountResult(
          success: false,
          message: 'User not authenticated. Please log in to continue.',
          errorCode: 'not_authenticated',
        );
      }

      final response = await _api.post(
        '/users/delete-account/',
        data: {'password': password},
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        return DeleteAccountResult(
          success: true,
          message: responseData['message'] ??
              'Your account has been successfully deleted. '
              'All personal information has been removed.',
        );
      }

      return DeleteAccountResult(
        success: false,
        message: responseData['message'] ?? 'Account deletion failed',
        errorCode: responseData['error'] ?? 'deletion_failed',
        isVendor: responseData['error'] == 'vendor_active',
      );
    } catch (e) {
      print('Error during account deletion: $e');
      return DeleteAccountResult(
        success: false,
        message:
            'An unexpected error occurred while deleting your account. '
            'Please try again or contact support.',
        errorCode: 'unknown_error',
      );
    }
  }

  static Future<bool> verifyPassword(String password) async {
    try {
      if (!AuthService.isAuthenticated()) return false;

      final response = await _api.post(
        '/users/verify-password/',
        data: {'password': password},
      );

      return response.data['verified'] == true;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

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
