import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../features/presentation/controllers/category_controller.dart';
import '../../features/presentation/controllers/auth_controller.dart';
import '../../features/presentation/controllers/cart_controller.dart';
import '../../features/presentation/controllers/search_controller.dart';
import '../../features/presentation/controllers/wishlist_controller.dart';
import '../../features/presentation/controllers/product_controller.dart';
import '../../features/presentation/controllers/home_controller.dart';
import '../../core/services/analytics_service.dart';
// import '../../features/presentation/controllers/category_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(GetStorage()); // Initialize GetStorage
    Get.put(AuthController());
    Get.put(CartController(), permanent: true); // Make it permanent
    Get.put(WishlistController());
    Get.put(ProductController());
    Get.put(HomeController());
    Get.put(AnalyticsService());
    Get.put(SearchController());
    Get.lazyPut(() => CategoryController());
  }
}
