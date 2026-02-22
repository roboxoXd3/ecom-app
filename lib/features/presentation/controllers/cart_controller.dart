import 'package:get/get.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'currency_controller.dart';

class CartController extends GetxController {
  final _api = ApiClient.instance;
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      isLoading.value = true;

      if (!AuthService.isAuthenticated()) {
        items.clear();
        return;
      }

      final response = await _api.get('/cart/');
      final data = response.data as Map<String, dynamic>;
      final cartItems = data['items'] as List<dynamic>? ?? [];

      items.value =
          cartItems
              .where((item) => item['product'] != null || item['products'] != null)
              .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList();
    } catch (e) {
      print('Error fetching cart items: $e');
      final s = e.toString();
      if (!SnackbarUtils.isNoInternet(e) &&
          !s.contains('no rows') &&
          !s.contains('404')) {
        SnackbarUtils.showError('Failed to load cart items');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(
    Product product,
    String size,
    String color, [
    int quantity = 1,
  ]) async {
    try {
      isLoading.value = true;

      if (!AuthService.isAuthenticated()) {
        SnackbarUtils.showError('Please login to add items to cart');
        return;
      }

      await _api.post('/cart/items/', data: {
        'product_id': product.id,
        'quantity': quantity,
        'selected_size': size,
        'selected_color': color,
      });

      await fetchCartItems();
    } catch (e) {
      print('Error adding to cart: $e');
      if (!SnackbarUtils.isNoInternet(e)) {
        SnackbarUtils.showError('Failed to add item to cart');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    try {
      isLoading.value = true;

      if (!AuthService.isAuthenticated()) {
        SnackbarUtils.showError('Please login to manage cart');
        return;
      }

      if (item.id != null) {
        await _api.delete('/cart/items/${item.id}/');
      }

      await fetchCartItems();
      SnackbarUtils.showSuccess('Removed from cart');
    } catch (e) {
      print('Error removing from cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQuantity(CartItem item, int quantity) async {
    if (quantity == 0) {
      await removeFromCart(item);
      return;
    }
    if (quantity < 1) return;

    if (!AuthService.isAuthenticated()) {
      SnackbarUtils.showError('Please login to update cart');
      return;
    }

    final oldQuantity = item.quantity;
    final index = items.indexOf(item);

    // Optimistic update: reflect the change in UI immediately
    if (index != -1) {
      items[index].quantity = quantity;
      items.refresh();
    }

    try {
      if (item.id != null) {
        await _api.patch('/cart/items/${item.id}/', data: {
          'quantity': quantity,
        });
      }
    } catch (e) {
      print('Error updating quantity: $e');
      // Revert on failure
      if (index != -1) {
        items[index].quantity = oldQuantity;
        items.refresh();
      }
      if (!SnackbarUtils.isNoInternet(e)) {
        SnackbarUtils.showError('Failed to update quantity');
      }
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;

      if (!AuthService.isAuthenticated()) {
        SnackbarUtils.showError('Please login to clear cart');
        return;
      }

      await _api.post('/cart/clear/');

      items.clear();
      SnackbarUtils.showSuccess('Cart cleared');
    } catch (e) {
      print('Error clearing cart: $e');
      if (!SnackbarUtils.isNoInternet(e)) {
        SnackbarUtils.showError('Failed to clear cart');
      }
    } finally {
      isLoading.value = false;
    }
  }

  double get total {
    if (!Get.isRegistered<CurrencyController>()) {
      return items.fold(
        0.0,
        (sum, item) => sum + item.product.price * item.quantity,
      );
    }

    final currencyController = Get.find<CurrencyController>();
    return items.fold(0.0, (sum, item) {
      final convertedPrice = currencyController.convertPrice(
        item.product.price,
        item.product.currency,
      );
      return sum + convertedPrice * item.quantity;
    });
  }
}
