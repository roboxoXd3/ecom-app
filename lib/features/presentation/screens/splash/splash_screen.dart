import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/utils/storage_utils.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/vendor_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
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
      final AuthController authController = Get.find<AuthController>();
      final isLoggedIn = authController.isLoggedIn();

      // The controllers already start fetching in onInit() via InitialBindings.
      // We simply wait for them to finish during the splash window so the home
      // screen opens with data already loaded — no double-fetching.
      Future<void> waitIfLoading(RxBool isLoading) async {
        // Poll until the in-progress fetch completes (max 8s safety cap)
        final deadline = DateTime.now().add(const Duration(seconds: 8));
        while (isLoading.value && DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final waitFutures = <Future>[
        if (Get.isRegistered<ProductController>())
          waitIfLoading(Get.find<ProductController>().isLoading),
        if (Get.isRegistered<CategoryController>())
          waitIfLoading(Get.find<CategoryController>().isLoading),
        if (Get.isRegistered<VendorController>())
          waitIfLoading(Get.find<VendorController>().isLoading),
        if (isLoggedIn) ...[
          if (Get.isRegistered<CartController>())
            waitIfLoading(Get.find<CartController>().isLoading),
          if (Get.isRegistered<OrderController>())
            waitIfLoading(Get.find<OrderController>().isLoading),
        ],
      ];

      // Wait for data + minimum splash duration simultaneously.
      // If data loads in 1.2s, we still show splash for 2s.
      // If data takes 3s, we skip the extra wait and navigate immediately.
      await Future.wait([
        Future.wait(waitFutures.map((f) => f.catchError((_) {}))),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (isLoggedIn) {
        Get.offAll(() => const HomeScreen());
      } else {
        final bool hasSeenOnboarding = await _hasSeenOnboarding();
        if (hasSeenOnboarding) {
          Get.offAll(() => const LoginScreen());
        } else {
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
      backgroundColor:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Use theme-aware background
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
                // Apply theme-aware color filter for dark mode visibility
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : null,
              ),
            ),
            const SizedBox(height: 24),
            // Title animation with faster timing
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Your One stop solution',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1.5,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                        Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
