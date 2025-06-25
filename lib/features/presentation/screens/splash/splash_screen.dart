import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/storage_utils.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Supabase is already initialized in main.dart
      final AuthController authController = Get.find<AuthController>();

      // Show animations for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      // Check if user is already logged in
      if (authController.isLoggedIn()) {
        // User is logged in, go directly to home screen
        Get.offAll(() => const HomeScreen());
      } else {
        // First time or logged out user, show onboarding
        final bool hasSeenOnboarding = await _hasSeenOnboarding();
        if (hasSeenOnboarding) {
          // User has seen onboarding before, go to login
          Get.offAll(() => const LoginScreen());
        } else {
          // First time user, show onboarding
          Get.offAll(() => const OnboardingScreen());
        }
      }
    } catch (e) {
      print('Error in splash screen: $e');
      Get.dialog(
        AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to initialize app: $e'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<bool> _hasSeenOnboarding() async {
    return await StorageUtils.hasSeenOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure consistent background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation with faster timing
            FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
              ),
            ),
            const SizedBox(height: 24),
            // Title animation with faster timing
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'Your One stop solution',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 600),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
