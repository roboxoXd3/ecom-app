import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';

class OrderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      print(
        'OrderRepository: Creating order with addressId: $addressId, paymentMethodId: $paymentMethodId',
      );

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Start a transaction by creating the order first
      final orderData = {
        'user_id': currentUser.id,
        'address_id': addressId,
        // Set payment_method_id to null for string-based payment methods
        'payment_method_id': null,
        'subtotal': subtotal,
        'shipping_fee': shippingFee,
        'total': total,
        'status': OrderStatus.pending.value,
        // Store the payment method type in shipping_method field temporarily
        // In a real app, you'd want a separate payment_method_type field
        'shipping_method': paymentMethodId,
      };

      // Add loyalty voucher code if provided
      if (loyaltyVoucherCode != null && loyaltyVoucherCode.isNotEmpty) {
        orderData['loyalty_voucher_code'] = loyaltyVoucherCode;
      }

      final orderResponse =
          await _supabase.from('orders').insert(orderData).select().single();

      print('OrderRepository: Order created with ID: ${orderResponse['id']}');

      final order = Order.fromJson(orderResponse);

      // Then create all order items
      final orderItems =
          items
              .map((item) => {...item.toJson(), 'order_id': order.id})
              .toList();

      print('OrderRepository: Creating ${orderItems.length} order items');

      await _supabase.from('order_items').insert(orderItems);

      print('OrderRepository: Order items created successfully');

      // Fetch the complete order with items
      return getOrder(order.id);
    } catch (e) {
      print('OrderRepository: Error creating order: $e');
      rethrow;
    }
  }

  Future<Order> getOrder(String orderId) async {
    final orderResponse =
        await _supabase.from('orders').select().eq('id', orderId).single();

    final itemsResponse = await _supabase
        .from('order_items')
        .select('''
          *,
          products!inner(
            id,
            name,
            vendor_id,
            vendors!inner(
              id,
              business_name
            )
          )
        ''')
        .eq('order_id', orderId);

    final items =
        (itemsResponse as List)
            .map((item) => OrderItem.fromJson(item))
            .toList();

    return Order.fromJson(orderResponse, items: items);
  }

  Future<List<Order>> getUserOrders() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final ordersResponse = await _supabase
        .from('orders')
        .select()
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    final orders = <Order>[];
    for (final orderJson in ordersResponse) {
      final itemsResponse = await _supabase
          .from('order_items')
          .select('''
            *,
            products!inner(
              id,
              name,
              vendor_id,
              vendors!inner(
                id,
                business_name
              )
            )
          ''')
          .eq('order_id', orderJson['id']);

      final items =
          (itemsResponse as List)
              .map((item) => OrderItem.fromJson(item))
              .toList();

      orders.add(Order.fromJson(orderJson, items: items));
    }

    return orders;
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
      print('OrderRepository: Creating order with payment details');
      print('Squad Transaction Ref: $squadTransactionRef');

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create order with payment details
      final orderData = {
        'user_id': currentUser.id,
        'address_id': addressId,
        'payment_method_id': null,
        'subtotal': subtotal,
        'shipping_fee': shippingFee,
        'total': total,
        'status': OrderStatus.pending.value,
        'shipping_method': paymentMethodId,
        'squad_transaction_ref': squadTransactionRef,
        'squad_gateway_ref': squadGatewayRef,
        'payment_status': paymentStatus,
        'escrow_status': escrowStatus,
      };

      // Add loyalty voucher code if provided
      if (loyaltyVoucherCode != null && loyaltyVoucherCode.isNotEmpty) {
        orderData['loyalty_voucher_code'] = loyaltyVoucherCode;
      }

      final orderResponse =
          await _supabase.from('orders').insert(orderData).select().single();

      print(
        'OrderRepository: Order with payment created with ID: ${orderResponse['id']}',
      );

      final order = Order.fromJson(orderResponse);

      // Create order items
      final orderItems =
          items
              .map((item) => {...item.toJson(), 'order_id': order.id})
              .toList();

      await _supabase.from('order_items').insert(orderItems);

      print('OrderRepository: Order items created successfully');

      // Return complete order with items
      return getOrder(order.id);
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
      final updateData = <String, dynamic>{'payment_status': paymentStatus};

      if (squadGatewayRef != null) {
        updateData['squad_gateway_ref'] = squadGatewayRef;
      }

      if (escrowStatus != null) {
        updateData['escrow_status'] = escrowStatus;
      }

      await _supabase.from('orders').update(updateData).eq('id', orderId);

      print('OrderRepository: Payment status updated for order: $orderId');
    } catch (e) {
      print('OrderRepository: Error updating payment status: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _supabase
        .from('orders')
        .update({'status': status.value})
        .eq('id', orderId);
  }
}
