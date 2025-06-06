import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../core/utils/snackbar_utils.dart';

class OrderController extends GetxController {
  final OrderRepository _repository = OrderRepository();
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    try {
      isLoading.value = true;
      orders.value = await _repository.getUserOrders();
    } catch (e) {
      SnackbarUtils.showError('Failed to fetch orders');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createOrder({
    required String addressId,
    required String paymentMethodId,
    required double subtotal,
    required double shippingFee,
    required double total,
    required List<OrderItem> items,
  }) async {
    try {
      isLoading.value = true;
      await _repository.createOrder(
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: items,
      );
      await fetchUserOrders();
      return true;
    } catch (e) {
      SnackbarUtils.showError('Failed to create order');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      isLoading.value = true;
      await _repository.updateOrderStatus(orderId, status);
      await fetchUserOrders();
    } catch (e) {
      SnackbarUtils.showError('Failed to update order status');
    } finally {
      isLoading.value = false;
    }
  }
}
