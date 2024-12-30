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
      // Test Supabase connection
      final supabase = Supabase.instance.client;
      final AuthController authController = Get.find<AuthController>();

      // Keep your existing delay for animations
      await Future.delayed(const Duration(seconds: 3));

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
    // You can use shared preferences to store this value
    // For now, returning false to always show onboarding
    // TODO: Implement proper storage of onboarding status
    return await StorageUtils.hasSeenOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation (keeping your existing animation)
            FadeInDown(
              duration: const Duration(milliseconds: 1500),
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
              ),
            ),
            const SizedBox(height: 24),
            // Title animation (keeping your existing animation)
            FadeInUp(
              duration: const Duration(milliseconds: 1500),
              child: const Text(
                'Your One stop solution',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
