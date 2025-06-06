import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

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
    // Start a transaction by creating the order first
    final orderResponse =
        await _supabase
            .from('orders')
            .insert({
              'user_id': _supabase.auth.currentUser!.id,
              'address_id': addressId,
              'payment_method_id': paymentMethodId,
              'subtotal': subtotal,
              'shipping_fee': shippingFee,
              'total': total,
              'status': 'pending',
            })
            .select()
            .single();

    final order = Order.fromJson(orderResponse);

    // Then create all order items
    final orderItems =
        items.map((item) => {...item.toJson(), 'order_id': order.id}).toList();

    await _supabase.from('order_items').insert(orderItems);

    // Fetch the complete order with items
    return getOrder(order.id);
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

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.from('orders').update({'status': status}).eq('id', orderId);
  }
}
