import 'order_status.dart';

double _toDouble(dynamic v) =>
    v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

int _toInt(dynamic v) =>
    v == null ? 0 : int.tryParse(v.toString()) ?? 0;

class Order {
  final String id;
  final String? orderNumber;
  final String userId;
  final String addressId;
  final String? paymentMethodId;
  final String? shippingMethod;
  final double subtotal;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  final String? squadTransactionRef;
  final String? squadGatewayRef;
  final String? paymentStatus;
  final String? escrowStatus;
  final DateTime? escrowReleaseDate;

  Order({
    required this.id,
    this.orderNumber,
    required this.userId,
    required this.addressId,
    this.paymentMethodId,
    this.shippingMethod,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
    this.squadTransactionRef,
    this.squadGatewayRef,
    this.paymentStatus,
    this.escrowStatus,
    this.escrowReleaseDate,
  });

  String get displayOrderNumber => orderNumber ?? '#${id.substring(0, 8).toUpperCase()}';

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    List<OrderItem> orderItems = items ?? [];
    if (orderItems.isEmpty && json['items'] is List) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString(),
      userId: json['user_id']?.toString() ?? json['user']?.toString() ?? '',
      addressId: json['address_id']?.toString() ?? json['address']?.toString() ?? '',
      paymentMethodId: json['payment_method_id']?.toString(),
      shippingMethod: json['shipping_method']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      shippingFee: _toDouble(json['shipping_fee']),
      total: _toDouble(json['total']),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: orderItems,
      squadTransactionRef: json['squad_transaction_ref'],
      squadGatewayRef: json['squad_gateway_ref'],
      paymentStatus: json['payment_status'],
      escrowStatus: json['escrow_status'],
      escrowReleaseDate:
          json['escrow_release_date'] != null
              ? DateTime.parse(json['escrow_release_date'])
              : null,
    );
  }

  // Helper method to get payment method display name
  String get paymentMethodDisplayName {
    switch (shippingMethod) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'upi':
        return 'UPI';
      case 'net_banking':
        return 'Net Banking';
      default:
        return shippingMethod ?? 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address_id': addressId,
      'payment_method_id': paymentMethodId,
      'shipping_method': shippingMethod,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'status': status.value,
      'squad_transaction_ref': squadTransactionRef,
      'squad_gateway_ref': squadGatewayRef,
      'payment_status': paymentStatus,
      'escrow_status': escrowStatus,
      'escrow_release_date': escrowReleaseDate?.toIso8601String(),
    };
  }

  // Helper methods for payment status
  bool get isPaymentPending => paymentStatus == 'pending';
  bool get isPaymentCompleted => paymentStatus == 'completed';
  bool get isPaymentFailed => paymentStatus == 'failed';

  bool get isEscrowHeld => escrowStatus == 'held';
  bool get isEscrowReleased => escrowStatus == 'released';

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'completed':
        return 'Payment Completed';
      case 'failed':
        return 'Payment Failed';
      default:
        return 'Unknown Status';
    }
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

  final String? productName;
  final String? productImage;
  final String? vendorId;
  final String? vendorName;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.selectedSize,
    required this.selectedColor,
    required this.createdAt,
    this.productName,
    this.productImage,
    this.vendorId,
    this.vendorName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String? productName;
    String? productImage;
    String? vendorId;
    String? vendorName;

    final product = json['product'] ?? json['products'];
    if (product is Map<String, dynamic>) {
      productName = product['name']?.toString();
      vendorId = product['vendor_id']?.toString();
      final images = product['images'];
      if (images is String && images.isNotEmpty) {
        productImage = images.split(',').first.trim();
      } else if (images is List && images.isNotEmpty) {
        productImage = images.first.toString();
      }
      final vendor = product['vendor'] ?? product['vendors'];
      if (vendor is Map<String, dynamic>) {
        vendorName = vendor['business_name']?.toString();
      }
    }

    final productId = json['product_id']?.toString()
        ?? (product is Map<String, dynamic> ? product['id']?.toString() : null)
        ?? '';

    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productId: productId,
      quantity: _toInt(json['quantity'] ?? 1),
      price: _toDouble(json['price']),
      selectedSize: json['selected_size'] ?? '',
      selectedColor: json['selected_color'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      productName: productName ?? json['product_name']?.toString(),
      productImage: productImage,
      vendorId: vendorId,
      vendorName: vendorName ?? json['vendor_name']?.toString(),
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
