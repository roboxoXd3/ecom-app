import 'package:ecom_app/features/presentation/controllers/auth_controller.dart';
import 'package:ecom_app/features/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../tabs/home_tab.dart';
import '../tabs/categories_tab.dart';
import '../tabs/cart_tab.dart';
import '../tabs/profile_tab.dart';
import '../../widgets/chatbot_fab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the controller but don't update state in build
    final homeController = Get.find<HomeController>();

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Obx(
            () => IndexedStack(
              index: homeController.currentIndex.value,
              children: [HomeTab(), CategoriesTab(), CartTab(), ProfileTab()],
            ),
          ),

          // Chatbot FAB overlay
          const ChatbotFAB(),
        ],
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: homeController.currentIndex.value,
          onDestinationSelected: (index) {
            final AuthController authController = Get.find<AuthController>();
            final isLoggedIn = authController.isLoggedIn();
            if (index == 3) {
              if (!isLoggedIn) {
                Get.to(() => const LoginScreen());
                homeController.currentIndex.value = 0;
              } else {
                homeController.currentIndex.value = index;
              }
            } else if (index == 2) {
              if (!isLoggedIn) {
                Get.to(() => const LoginScreen());
                homeController.currentIndex.value = 0;
              } else {
                homeController.currentIndex.value = index;
              }
            }else {
              homeController.currentIndex.value = index;

            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
