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
      SnackbarUtils.showError('Please enter a valid email');
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
        SnackbarUtils.showSuccess(
          'Registration successful! Please check your email to verify your account.',
        );
        Get.back(); // Go back to login screen
      } else {
        throw 'Registration failed';
      }
    } catch (e) {
      SnackbarUtils.showError('Registration failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      SnackbarUtils.showError('Please fill in all fields');
      return;
    }

    if (!GetUtils.isEmail(email.value)) {
      SnackbarUtils.showError('Please enter a valid email');
      return;
    }

    try {
      isLoading.value = true;
      print('Attempting login with email: ${email.value}'); // Debug print

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email.value,
        password: password.value,
      );

      print(
        'Auth response: ${response.user != null ? 'User exists' : 'No user'}',
      ); // Debug print
      print(
        'User email verified: ${response.user?.emailConfirmedAt != null}',
      ); // Check email verification

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          SnackbarUtils.showError('Please verify your email first');
          return;
        }

        updateUserData();

        SnackbarUtils.showSuccess('Login successful');
        Get.offAll(() => const HomeScreen());
      } else {
        throw 'Login failed';
      }
    } catch (e) {
      print('Login error details: $e'); // Debug print
      SnackbarUtils.showError('Login failed: ${e.toString()}');
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
    try {
      isLoading.value = true;

      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );

      SnackbarUtils.showSuccess(
        'Password reset link has been sent to your email',
      );
    } catch (e) {
      print('Reset password error: $e');
      SnackbarUtils.showError('Failed to send reset link: ${e.toString()}');
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
      userEmail.value = user.email ?? '';

      print('User metadata: ${user.userMetadata}');
      print('Full name from metadata: ${user.userMetadata?['full_name']}');

      userName.value =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@')[0] ??
          'User';

      print('Final userName value: ${userName.value}');
    }
  }

  @override
  void onInit() {
    super.onInit();
    updateUserData();
  }
}
