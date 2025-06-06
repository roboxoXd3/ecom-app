class Order {
  final String id;
  final String userId;
  final String addressId;
  final String paymentMethodId;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.paymentMethodId,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      addressId: json['address_id'],
      paymentMethodId: json['payment_method_id'],
      subtotal: json['subtotal'].toDouble(),
      shippingFee: json['shipping_fee'].toDouble(),
      total: json['total'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      items: items ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address_id': addressId,
      'payment_method_id': paymentMethodId,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'status': status,
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;
  final String selectedSize;
  final String selectedColor;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.selectedSize,
    required this.selectedColor,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      selectedSize: json['selected_size'],
      selectedColor: json['selected_color'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'selected_size': selectedSize,
      'selected_color': selectedColor,
    };
  }
}
