import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;

  void togglePasswordVisibility() => isPasswordVisible.toggle();

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

      // Register user with Supabase
      final AuthResponse response = await supabase.auth.signUp(
        email: email.value,
        password: password.value,
        data: {'full_name': fullName.value},
      );

      if (response.user != null) {
        print('✅ Registration successful for user: ${response.user!.email}');

        // Clear form fields first
        fullName.value = '';
        email.value = '';
        password.value = '';
        confirmPassword.value = '';

        // Set loading to false immediately
        isLoading.value = false;

        // Show success message
        SnackbarUtils.showSuccess(
          '🎉 Account created successfully!\nPlease check your email to verify your account before signing in.',
        );

        print('📧 Success message shown, preparing to navigate...');

        // Simple approach: Use Timer to avoid async/await conflicts
        Timer(const Duration(milliseconds: 1500), () {
          print('⏰ NEW VERSION - Timer triggered, navigating with Get.off...');
          try {
            // Use Get.off instead of Get.back to avoid snackbar conflicts
            Get.off(() => const LoginScreen());
            print(
              '✅ NEW VERSION - Navigation completed successfully with Get.off',
            );
          } catch (e) {
            print('❌ Navigation failed: $e');
            // Fallback
            Get.offAllNamed('/login');
          }
        });

        return; // Important: return here to avoid setting isLoading to false again
      } else {
        throw 'Registration failed - please try again';
      }
    } on AuthException catch (e) {
      // Handle specific Supabase auth errors
      String errorMessage = 'Registration failed';

      if (e.message.contains('already registered')) {
        errorMessage =
            'An account with this email already exists. Please sign in instead.';
      } else if (e.message.contains('weak password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.message.contains('invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }

      SnackbarUtils.showError(errorMessage);
    } catch (e) {
      SnackbarUtils.showError('Registration failed: ${e.toString()}');
    } finally {
      // Only set loading to false if we haven't already done it in the success case
      if (isLoading.value) {
        isLoading.value = false;
      }
    }
  }

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
      print('🔐 Attempting login with email: ${email.value}');

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email.value,
        password: password.value,
      );

      print(
        '✅ Auth response received: ${response.user != null ? 'User exists' : 'No user'}',
      );

      if (response.user != null) {
        // Check if email is verified
        if (response.user!.emailConfirmedAt == null) {
          SnackbarUtils.showError(
            '📧 Email not verified!\nPlease check your email and click the verification link before signing in.',
          );
          return;
        }

        // Login successful
        updateUserData();

        // Clear password field for security
        password.value = '';

        SnackbarUtils.showSuccess('🎉 Welcome back! Login successful');

        print('🏠 Navigating to home screen...');
        Get.offAll(() => const HomeScreen());
      } else {
        throw 'Authentication failed - please check your credentials';
      }
    } on AuthException catch (e) {
      // Handle specific Supabase auth errors with user-friendly messages
      String errorMessage = '🚫 Login failed';

      print('🔍 AuthException details: ${e.message}');

      if (e.message.contains('Invalid login credentials') ||
          e.message.contains('invalid credentials') ||
          e.message.contains('Email not confirmed')) {
        errorMessage =
            '❌ Invalid email or password.\nPlease check your credentials and try again.';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage =
            '📧 Please verify your email first.\nCheck your inbox for the verification link.';
      } else if (e.message.contains('Too many requests')) {
        errorMessage =
            '⏰ Too many login attempts.\nPlease wait a few minutes and try again.';
      } else if (e.message.contains('User not found')) {
        errorMessage =
            '👤 No account found with this email.\nPlease register first or check your email address.';
      } else if (e.message.contains('network')) {
        errorMessage =
            '🌐 Network error.\nPlease check your internet connection and try again.';
      } else if (e.message.contains('timeout')) {
        errorMessage =
            '⏱️ Connection timeout.\nPlease check your internet connection and try again.';
      } else {
        errorMessage = '🚫 Login failed: ${e.message}';
      }

      SnackbarUtils.showError(errorMessage);
    } catch (e) {
      print('🔍 General error details: $e');

      // Handle general errors with user-friendly messages
      String errorMessage = '🚫 Login failed';

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            '🌐 Network error.\nPlease check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '⏱️ Connection timeout.\nPlease try again in a moment.';
      } else {
        errorMessage =
            '🚫 Something went wrong.\nPlease try again or contact support if the problem persists.';
      }

      SnackbarUtils.showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Add method to check if user is already logged in
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // Add method to handle logout
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();
      // Clear any local user data if needed
      fullName.value = '';
      email.value = '';
      password.value = '';
      confirmPassword.value = '';
    } catch (e) {
      SnackbarUtils.showError('Logout failed: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      SnackbarUtils.showError('Please enter your email address');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      SnackbarUtils.showError('Please enter a valid email address');
      return;
    }

    try {
      isLoading.value = true;
      print('📧 Sending password reset email to: $email');

      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );

      SnackbarUtils.showSuccess(
        '📧 Password reset link sent!\nPlease check your email (including spam folder) and follow the instructions.',
      );
    } on AuthException catch (e) {
      print('🔍 Password reset AuthException: ${e.message}');

      String errorMessage = '🚫 Failed to send reset link';

      if (e.message.contains('not found') || e.message.contains('no user')) {
        errorMessage =
            '👤 No account found with this email address.\nPlease check the email or register for a new account.';
      } else if (e.message.contains('rate limit') ||
          e.message.contains('too many')) {
        errorMessage =
            '⏰ Too many reset attempts.\nPlease wait a few minutes before trying again.';
      } else if (e.message.contains('network')) {
        errorMessage =
            '🌐 Network error.\nPlease check your internet connection and try again.';
      } else {
        errorMessage = '🚫 Failed to send reset link: ${e.message}';
      }

      SnackbarUtils.showError(errorMessage);
    } catch (e) {
      print('🔍 Password reset general error: $e');

      String errorMessage = '🚫 Failed to send reset link';

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            '🌐 Network error.\nPlease check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '⏱️ Connection timeout.\nPlease try again in a moment.';
      } else {
        errorMessage =
            '🚫 Something went wrong.\nPlease try again or contact support if the problem persists.';
      }

      SnackbarUtils.showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      SnackbarUtils.showSuccess('Password updated successfully');
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print('Update password error: $e');
      SnackbarUtils.showError('Failed to update password: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void updateUserData() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Set the currentUser observable
      currentUser.value = user;
      userEmail.value = user.email ?? '';

      print('User metadata: ${user.userMetadata}');
      print('Full name from metadata: ${user.userMetadata?['full_name']}');

      userName.value =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@')[0] ??
          'User';

      print('Final userName value: ${userName.value}');
      print('Current user email set to: ${userEmail.value}');
    } else {
      // Clear user data if no user is logged in
      currentUser.value = null;
      userEmail.value = '';
      userName.value = '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    updateUserData();
  }
}
