import 'package:get/get.dart';
import '../../features/presentation/controllers/payment_method_controller.dart';
import '../../features/presentation/screens/category/category_details_screen.dart';

import '../../features/presentation/screens/product/real_enhanced_product_details_screen.dart';
import '../../features/presentation/screens/profile/add_address_screen.dart';
import '../../features/presentation/screens/profile/my_orders_screen.dart';
import '../../features/presentation/screens/profile/order_details_screen.dart';
import '../../features/presentation/screens/profile/shipping_address_screen.dart';
import '../../features/presentation/screens/order/order_confirmation_screen.dart';
import '../../features/presentation/screens/splash/splash_screen.dart';
import '../../features/presentation/screens/auth/login_screen.dart';
import '../../features/presentation/screens/home/home_screen.dart';
import '../../features/presentation/screens/search/search_screen.dart';
import '../../features/presentation/screens/search/search_results_screen.dart';

import '../../features/presentation/controllers/enhanced_product_controller.dart';
import '../../features/presentation/controllers/product_controller.dart';
import '../../features/presentation/screens/profile/payment_methods_screen.dart';
import '../../features/presentation/screens/profile/add_card_screen.dart';
import '../../features/presentation/screens/vendor/vendors_list_screen.dart';
import '../../features/presentation/screens/checkout/checkout_screen.dart';

import '../../features/presentation/controllers/order_controller.dart';
import '../../features/presentation/controllers/loyalty_controller.dart';
import '../../features/presentation/screens/loyalty/loyalty_home_screen.dart';
import '../../features/presentation/screens/loyalty/rewards_catalog_screen.dart';
import '../../features/presentation/screens/loyalty/my_vouchers_screen.dart';
import '../../features/presentation/screens/loyalty/transaction_history_screen.dart';
import '../../features/presentation/screens/loyalty/badges_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String productDetails = '/product-details';
  static const String enhancedProductDetails = '/enhanced-product-details';
  static const String categoryDetails = '/category/:id';
  static const String shippingAddresses = '/shipping-addresses';
  static const String addAddress = '/add-address';
  static const String paymentMethods = '/payment-methods';
  static const String addCard = '/add-card';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String orderConfirmation = '/order-confirmation';
  static const String vendorsList = '/vendors-list';
  static const String checkout = '/checkout';
  static const String loyaltyHome = '/loyalty-home';
  static const String rewardsCatalog = '/rewards-catalog';
  static const String myVouchers = '/my-vouchers';
  static const String transactionHistory = '/transaction-history';
  static const String badges = '/badges';

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
      page: () => RealEnhancedProductDetailsScreen(productId: Get.arguments),
      binding: BindingsBuilder(() {
        Get.put(EnhancedProductController());
        Get.lazyPut(() => ProductController()); // For wishlist functionality
      }),
    ),
    GetPage(
      name: enhancedProductDetails,
      page: () => RealEnhancedProductDetailsScreen(productId: Get.arguments),
      binding: BindingsBuilder(() {
        Get.put(EnhancedProductController());
        Get.lazyPut(() => ProductController()); // For wishlist functionality
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
    GetPage(
      name: orderConfirmation,
      page: () => const OrderConfirmationScreen(),
      binding: BindingsBuilder(() {
        Get.put(OrderController());
      }),
    ),
    GetPage(name: vendorsList, page: () => const VendorsListScreen()),
    GetPage(
      name: checkout,
      page: () => const CheckoutScreen(),
      binding: BindingsBuilder(() {
        Get.put(OrderController());
      }),
    ),
    GetPage(
      name: loyaltyHome,
      page: () => const LoyaltyHomeScreen(),
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
    GetPage(
      name: rewardsCatalog,
      page: () => const RewardsCatalogScreen(),
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
    GetPage(
      name: myVouchers,
      page: () => const MyVouchersScreen(),
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
    GetPage(
      name: transactionHistory,
      page: () => const TransactionHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
    GetPage(
      name: badges,
      page: () => const BadgesScreen(),
      binding: BindingsBuilder(() {
        Get.put(LoyaltyController());
      }),
    ),
  ];
}
