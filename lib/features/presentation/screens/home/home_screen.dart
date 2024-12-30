import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../tabs/home_tab.dart';
import '../tabs/categories_tab.dart';
import '../tabs/cart_tab.dart';
import '../tabs/profile_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    // Check if we have arguments for tab index
    if (Get.arguments != null) {
      homeController.currentIndex.value = Get.arguments as int;
    }

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: homeController.currentIndex.value,
          children: [HomeTab(), CategoriesTab(), CartTab(), ProfileTab()],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: homeController.currentIndex.value,
          onDestinationSelected:
              (index) => homeController.currentIndex.value = index,
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
