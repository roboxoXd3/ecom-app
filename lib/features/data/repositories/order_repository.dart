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
  }) async {
    try {
      print(
        'OrderRepository: Creating order with addressId: $addressId, paymentMethodId: $paymentMethodId',
      );

      // Check if user is authenticated
      if (_supabase.auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Start a transaction by creating the order first
      final orderResponse =
          await _supabase
              .from('orders')
              .insert({
                'user_id': _supabase.auth.currentUser!.id,
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
              })
              .select()
              .single();

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
        .select()
        .eq('order_id', orderId);

    final items =
        (itemsResponse as List)
            .map((item) => OrderItem.fromJson(item))
            .toList();

    return Order.fromJson(orderResponse, items: items);
  }

  Future<List<Order>> getUserOrders() async {
    final ordersResponse = await _supabase
        .from('orders')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    final orders = <Order>[];
    for (final orderJson in ordersResponse) {
      final itemsResponse = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderJson['id']);

      final items =
          (itemsResponse as List)
              .map((item) => OrderItem.fromJson(item))
              .toList();

      orders.add(Order.fromJson(orderJson, items: items));
    }

    return orders;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _supabase
        .from('orders')
        .update({'status': status.value})
        .eq('id', orderId);
  }
}
