import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';
import '../../../core/services/auth_service.dart';
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

      if (!AuthService.isAuthenticated()) {
        orders.clear();
        return;
      }

      orders.value = await _repository.getUserOrders();
    } catch (e) {
      print('Error fetching orders: $e');
      if (!SnackbarUtils.isNoInternet(e) && AuthService.isAuthenticated()) {
        SnackbarUtils.showError('Failed to fetch orders');
      }
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
        escrowStatus: escrowStatus ?? 'held',
        loyaltyVoucherCode: loyaltyVoucherCode,
      );

      await fetchUserOrders();
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

      await fetchUserOrders();
    } catch (e) {
      print('Error updating payment status: $e');
      SnackbarUtils.showError('Failed to update payment status');
    }
  }

  /// Creates an order with pending payment status and returns the Order object.
  /// Used by CheckoutController before initiating online payment so we have
  /// the order_id to pass to the payment gateway.
  Future<Order?> createOnlinePaymentOrder({
    required String addressId,
    required String paymentMethodId,
    required double subtotal,
    required double shippingFee,
    required double total,
    required List<OrderItem> items,
    String? loyaltyVoucherCode,
  }) async {
    try {
      final order = await _repository.createOrderWithPayment(
        addressId: addressId,
        paymentMethodId: paymentMethodId,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: items,
        paymentStatus: 'pending',
        loyaltyVoucherCode: loyaltyVoucherCode,
      );
      return order;
    } catch (e) {
      print('OrderController: Error creating online payment order: $e');
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      isLoading.value = true;
      await _repository.updateOrderStatus(orderId, status.value);
      await fetchUserOrders();
    } catch (e) {
      SnackbarUtils.showError('Failed to update order status');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final success = await _repository.cancelOrder(orderId);
      if (success) {
        await fetchUserOrders();
      }
      return success;
    } catch (e) {
      print('OrderController: Error cancelling order: $e');
      return false;
    }
  }
}
