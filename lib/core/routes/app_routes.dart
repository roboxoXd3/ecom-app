import 'package:get/get.dart';
import '../../features/presentation/controllers/payment_method_controller.dart';
import '../../features/presentation/screens/category/category_details_screen.dart';
import '../../features/presentation/screens/product/product_details_screen.dart';
import '../../features/presentation/screens/profile/add_address_screen.dart';
import '../../features/presentation/screens/profile/my_orders_screen.dart';
import '../../features/presentation/screens/profile/order_details_screen.dart';
import '../../features/presentation/screens/profile/shipping_address_screen.dart';
import '../../features/presentation/screens/splash/splash_screen.dart';
import '../../features/presentation/screens/auth/login_screen.dart';
import '../../features/presentation/screens/home/home_screen.dart';
import '../../features/presentation/screens/search/search_screen.dart';
import '../../features/presentation/screens/search/search_results_screen.dart';
import '../../features/presentation/screens/analytics/analytics_screen.dart';
import '../../features/presentation/controllers/analytics_controller.dart';
import '../../features/presentation/controllers/product_details_controller.dart';
import '../../features/presentation/screens/profile/payment_methods_screen.dart';
import '../../features/presentation/screens/profile/add_card_screen.dart';

import '../../features/presentation/controllers/order_controller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String productDetails = '/product-details';
  static const String analytics = '/analytics';
  static const String categoryDetails = '/category/:id';
  static const String shippingAddresses = '/shipping-addresses';
  static const String addAddress = '/add-address';
  static const String paymentMethods = '/payment-methods';
  static const String addCard = '/add-card';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';

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
      binding: BindingsBuilder(() {
        Get.put(ProductDetailsController());
      }),
    ),
    GetPage(
      name: analytics,
      page: () => AnalyticsScreen(),
      binding: BindingsBuilder(() {
        Get.put(AnalyticsController());
      }),
    ),
    GetPage(
      name: categoryDetails,
      page: () => CategoryDetailsScreen(category: Get.arguments),
    ),
    GetPage(name: shippingAddresses, page: () => ShippingAddressScreen()),
    GetPage(
      name: addAddress,
      page:
          () => AddAddressScreen(
            isEditing: Get.arguments?['isEditing'] ?? false,
            address: Get.arguments?['address'],
          ),
    ),
    GetPage(
      name: paymentMethods,
      page: () => PaymentMethodsScreen(),
      binding: BindingsBuilder(() {
        Get.put(PaymentMethodController());
      }),
    ),
    GetPage(name: addCard, page: () => const AddCardScreen()),
    GetPage(
      name: orders,
      page: () => MyOrdersScreen(),
      binding: BindingsBuilder(() {
        Get.put(OrderController());
      }),
    ),
    GetPage(
      name: orderDetails,
      page: () => OrderDetailsScreen(orderId: Get.arguments),
      binding: BindingsBuilder(() {
        Get.put(OrderController());
      }),
    ),
  ];
}
