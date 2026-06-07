import 'package:flutter/foundation.dart';

import 'package:get/get.dart';

import 'cart_controller.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers
    Get.put(CartController(), permanent: true);

    // Handle direct navigation to cart tab
    ever(currentIndex, (index) {
      debugPrint('Tab index changed to: $index'); // Debug print
    });
  }

  void navigateToTab(int index) {
    debugPrint('Navigating to tab: $index'); // Debug print
    currentIndex.value = index;
  }

  void changeTab(int index) {
    navigateToTab(index); // Use the same method for consistency
  }
}
