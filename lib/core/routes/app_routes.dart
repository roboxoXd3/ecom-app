import 'package:get/get.dart';
import '../../features/presentation/screens/product/product_details_screen.dart';
import '../../features/presentation/screens/splash/splash_screen.dart';
import '../../features/presentation/screens/auth/login_screen.dart';
import '../../features/presentation/screens/home/home_screen.dart';
import '../../features/presentation/screens/search/search_screen.dart';
import '../../features/presentation/screens/search/search_results_screen.dart';
import '../../features/presentation/screens/analytics/analytics_screen.dart';
import '../../features/presentation/controllers/analytics_controller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String productDetails = '/product-details';
  static const String analytics = '/analytics';

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(
      name: searchResults,
      page: () => SearchResultsScreen(query: Get.arguments),
    ),
    GetPage(
      name: productDetails,
      page: () => ProductDetailsScreen(product: Get.arguments),
    ),
    GetPage(
      name: analytics,
      page: () => AnalyticsScreen(),
      binding: BindingsBuilder(() {
        Get.put(AnalyticsController());
      }),
    ),
  ];
}
