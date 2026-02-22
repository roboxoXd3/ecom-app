import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import 'product_controller.dart';

class AuthController extends GetxController {
  final _api = ApiClient.instance;

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;

  void togglePasswordVisibility() => isPasswordVisible.toggle();

  // ---------------------------------------------------------------------------
  // Register — POST /api/users/register/
  // ---------------------------------------------------------------------------
  Future<void> register() async {
    if (fullName.value.isEmpty ||
        email.value.isEmpty ||
        password.value.isEmpty ||
        confirmPassword.value.isEmpty) {
      SnackbarUtils.showError('Please fill in all fields');
      return;
    }

    if (!GetUtils.isEmail(email.value)) {
      SnackbarUtils.showError('Please enter a valid email address');
      return;
    }

    if (password.value.length < 6) {
      SnackbarUtils.showError('Password must be at least 6 characters long');
      return;
    }

    if (password.value != confirmPassword.value) {
      SnackbarUtils.showError('Passwords do not match');
      return;
    }

    try {
      isLoading.value = true;

      await _api.post('/users/register/', data: {
        'email': email.value,
        'password': password.value,
        'first_name': fullName.value,
      });

      fullName.value = '';
      email.value = '';
      password.value = '';
      confirmPassword.value = '';
      isLoading.value = false;

      Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            title: Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: Get.theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Account created successfully!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We\'ve sent a verification link to your email.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Check your email inbox\n2. Click the verification link\n3. Return here to sign in',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.off(() => const LoginScreen());
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Get.theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Got It!'),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, fallback: 'Registration failed');
      SnackbarUtils.showError(msg);
    } catch (e) {
      SnackbarUtils.showError('Registration failed: ${e.toString()}');
    } finally {
      if (isLoading.value) isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Login — POST /api/users/login/
  // Django returns { session: { access_token, refresh_token, ... }, user: {...} }
  // We save tokens and user info to local GetStorage.
  // ---------------------------------------------------------------------------
  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      SnackbarUtils.showError('Please fill in all fields');
      return;
    }

    if (!GetUtils.isEmail(email.value)) {
      SnackbarUtils.showError('Please enter a valid email address');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _api.post('/users/login/', data: {
        'email': email.value,
        'password': password.value,
      });

      final data = response.data as Map<String, dynamic>;
      final rawSession = data['session'];

      if (rawSession == null) {
        SnackbarUtils.showError(
          'Email not verified! Please check your email and click the verification link before signing in.',
        );
        isLoading.value = false;
        return;
      }

      final session = _normalizeSession(rawSession);

      final accessToken = session['access_token'] as String?;
      final refreshToken = session['refresh_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        SnackbarUtils.showError('Login failed — no access token received.');
        isLoading.value = false;
        return;
      }

      // Extract user info from the response
      final userData = data['user'] as Map<String, dynamic>? ?? {};
      final userId = userData['id']?.toString() ??
          session['user']?['id']?.toString() ?? '';
      final userEmailStr = userData['email']?.toString() ??
          session['user']?['email']?.toString() ?? email.value;

      // Extract name from user_metadata if available
      final sessionUser = session['user'];
      final metadata = sessionUser is Map
          ? sessionUser['user_metadata'] as Map<String, dynamic>?
          : null;
      final nameFromMeta = metadata?['full_name'] ??
          metadata?['name'] ??
          metadata?['first_name'];

      await AuthService.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        email: userEmailStr,
        fullName: nameFromMeta?.toString(),
        userMetadata: metadata,
      );

      updateUserData();
      password.value = '';
      isLoading.value = false;

      // Reload wishlist now that user is authenticated
      try {
        final productController = Get.find<ProductController>();
        productController.loadWishlist();
      } catch (_) {}

      SnackbarUtils.showSuccess('Welcome back! Login successful');
      Get.offAll(() => const HomeScreen());
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, fallback: 'Login failed');
      SnackbarUtils.showError(msg);
    } catch (e) {
      SnackbarUtils.showError(
        'Something went wrong. Please try again or contact support.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Logout — POST /api/users/logout/
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    try {
      isLoading.value = true;

      try {
        await _api.post('/users/logout/');
      } catch (_) {}

      await AuthService.clearSession();

      fullName.value = '';
      email.value = '';
      password.value = '';
      confirmPassword.value = '';
      userName.value = '';
      userEmail.value = '';
    } catch (e) {
      SnackbarUtils.showError('Logout failed: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Check auth state (reads local storage — no network call)
  // ---------------------------------------------------------------------------
  bool isLoggedIn() {
    return AuthService.isAuthenticated();
  }

  // ---------------------------------------------------------------------------
  // Forgot password — POST /api/users/password/reset/
  // ---------------------------------------------------------------------------
  Future<void> forgotPassword(String emailAddress) async {
    if (emailAddress.isEmpty) {
      SnackbarUtils.showError('Please enter your email address');
      return;
    }

    if (!GetUtils.isEmail(emailAddress)) {
      SnackbarUtils.showError('Please enter a valid email address');
      return;
    }

    try {
      isLoading.value = true;

      await _api.post('/users/password/reset/', data: {
        'email': emailAddress,
      });

      SnackbarUtils.showSuccess(
        'Password reset link sent! Please check your email (including spam folder).',
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, fallback: 'Failed to send reset link');
      SnackbarUtils.showError(msg);
    } catch (e) {
      SnackbarUtils.showError('Failed to send reset link. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Change password — POST /api/users/password/change/
  // ---------------------------------------------------------------------------
  Future<void> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;

      await _api.post('/users/password/change/', data: {
        'password': newPassword,
      });

      SnackbarUtils.showSuccess('Password updated successfully');
      Get.offAll(() => const LoginScreen());
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, fallback: 'Failed to update password');
      SnackbarUtils.showError(msg);
    } catch (e) {
      SnackbarUtils.showError('Failed to update password: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Update local observable state from stored session
  // ---------------------------------------------------------------------------
  void updateUserData() {
    if (AuthService.isAuthenticated()) {
      userEmail.value = AuthService.getUserEmail() ?? '';
      userName.value = AuthService.getUserName();
    } else {
      userEmail.value = '';
      userName.value = '';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _normalizeSession(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);

    if (raw is List) {
      final map = <String, dynamic>{};
      for (final entry in raw) {
        if (entry is List && entry.length >= 2) {
          map[entry[0].toString()] = entry[1];
        }
      }
      return map;
    }

    return {};
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      try {
        final apiError = ApiException.fromResponse(
          e.response!.data,
          statusCode: e.response!.statusCode,
        );
        if (apiError.message.isNotEmpty && apiError.message != 'An error occurred') {
          return apiError.message;
        }
      } catch (_) {}
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }

    return fallback;
  }

  @override
  void onInit() {
    super.onInit();
    updateUserData();
  }
}
