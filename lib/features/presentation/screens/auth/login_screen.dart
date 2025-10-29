import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import '../../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put with permanent: true to ensure the controller persists across auth screens
    final AuthController controller = Get.put(
      AuthController(),
      permanent: true,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add space for top padding
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Welcome Text
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Email Field
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 500),
                  child: TextField(
                    onChanged: (value) => controller.email.value = value,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.getBorder(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.getBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.getSurface(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                FadeInDown(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 500),
                  child: Obx(
                    () => TextField(
                      onChanged: (value) => controller.password.value = value,
                      obscureText: !controller.isPasswordVisible.value,
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppTheme.getTextSecondary(context),
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorder(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.getBorder(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.getSurface(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password
                FadeInDown(
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 500),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => ForgotPasswordScreen()),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ),

                // Add space before buttons
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                // Login Button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Obx(
                    () => ElevatedButton(
                      onPressed:
                          controller.isLoading.value
                              ? null
                              : () => controller.login(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          controller.isLoading.value
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Option
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => const RegisterScreen()),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),

                // Add bottom padding for keyboard
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
