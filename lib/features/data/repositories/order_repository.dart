import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _api = ApiClient.instance;

  Future<Order> createOrder({
    required String addressId,
    required String paymentMethodId,
    required double subtotal,
    required double shippingFee,
    required double total,
    required List<OrderItem> items,
    String? loyaltyVoucherCode,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{
        'address_id': addressId,
        'shipping_method': paymentMethodId,
        'notes': '',
        'items': items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'selected_size': item.selectedSize,
                  'selected_color': item.selectedColor,
                })
            .toList(),
      };

      if (loyaltyVoucherCode != null && loyaltyVoucherCode.isNotEmpty) {
        data['loyalty_voucher_code'] = loyaltyVoucherCode;
      }

      if (paymentMethodId == 'cash_on_delivery') {
        data['payment_status'] = 'pending';
      }

      final response = await _api.post('/orders/', data: data);
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('OrderRepository: Error creating order: ${e.response?.statusCode} — ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('OrderRepository: Error creating order: $e');
      rethrow;
    }
  }

  Future<Order> getOrder(String orderId) async {
    final response = await _api.get('/orders/$orderId/');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Order>> getUserOrders() async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    final response = await _api.get('/orders/');
    final results = ApiClient.unwrapResults(response.data);
    return results
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Order> createOrderWithPayment({
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
      if (!AuthService.isAuthenticated()) {
        throw Exception('User not authenticated');
      }

      final data = <String, dynamic>{
        'address_id': addressId,
        'shipping_method': paymentMethodId,
        'items': items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'selected_size': item.selectedSize,
                  'selected_color': item.selectedColor,
                })
            .toList(),
      };

      if (squadTransactionRef != null) {
        data['squad_transaction_ref'] = squadTransactionRef;
      }
      if (paymentStatus != null) {
        data['payment_status'] = paymentStatus;
      }
      if (loyaltyVoucherCode != null && loyaltyVoucherCode.isNotEmpty) {
        data['loyalty_voucher_code'] = loyaltyVoucherCode;
      }

      final response = await _api.post('/orders/', data: data);
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('OrderRepository: Error creating order with payment: ${e.response?.statusCode} — ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('OrderRepository: Error creating order with payment: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? squadGatewayRef,
    String? escrowStatus,
  }) async {
    try {
      final data = <String, dynamic>{'payment_status': paymentStatus};
      if (squadGatewayRef != null) {
        data['squad_gateway_ref'] = squadGatewayRef;
      }
      if (escrowStatus != null) {
        data['escrow_status'] = escrowStatus;
      }

      await _api.patch('/orders/$orderId/payment-status/', data: data);
    } catch (e) {
      print('OrderRepository: Error updating payment status: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String statusValue) async {
    await _api.patch('/orders/$orderId/', data: {
      'status': statusValue,
    });
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _api.post('/orders/$orderId/cancel/');
      return true;
    } catch (e) {
      print('OrderRepository: Error cancelling order: $e');
      return false;
    }
  }
}
