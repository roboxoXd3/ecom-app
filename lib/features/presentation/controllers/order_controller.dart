import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
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
    String? loyaltyVoucherCode,
  }) async {
    try {
      print('OrderController: Creating order with ${items.length} items');
      isLoading.value = true;

      await _repository.createOrder(
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: items,
        loyaltyVoucherCode: loyaltyVoucherCode,
      );

      print('OrderController: Order created successfully');
      await fetchUserOrders();
      return true;
    } catch (e) {
      print('OrderController: Error creating order: $e');
      SnackbarUtils.showError('Failed to create order: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createOrderWithPayment({
    required String addressId,
    required String paymentMethodId,
    required double subtotal,
    required double shippingFee,
    required double total,
    required List<OrderItem> items,
    String? squadTransactionRef,
    String? squadGatewayRef,
    String? paymentStatus,
    String? escrowStatus,
    String? loyaltyVoucherCode,
  }) async {
    try {
      print('OrderController: Creating order with payment details');
      print('Squad Transaction Ref: $squadTransactionRef');
      print('Payment Status: $paymentStatus');

      isLoading.value = true;

      await _repository.createOrderWithPayment(
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: items,
        squadTransactionRef: squadTransactionRef,
        squadGatewayRef: squadGatewayRef,
        paymentStatus: paymentStatus,
        escrowStatus: escrowStatus ?? 'held', // Default to held for marketplace
        loyaltyVoucherCode: loyaltyVoucherCode,
      );

      print('OrderController: Order with payment created successfully');
      await fetchUserOrders(); // Refresh orders list
      return true;
    } catch (e) {
      print('OrderController: Error creating order with payment - $e');
      SnackbarUtils.showError('Failed to create order with payment details');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? squadGatewayRef,
    String? escrowStatus,
  }) async {
    try {
      await _repository.updatePaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
        squadGatewayRef: squadGatewayRef,
        escrowStatus: escrowStatus,
      );

      // Refresh orders to show updated status
      await fetchUserOrders();

      print('Payment status updated for order: $orderId');
    } catch (e) {
      print('Error updating payment status: $e');
      SnackbarUtils.showError('Failed to update payment status');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
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
