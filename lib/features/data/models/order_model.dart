import 'order_status.dart';

class Order {
  final String id;
  final String userId;
  final String addressId;
  final String? paymentMethodId;
  final String? shippingMethod; // Used to store payment method type
  final double subtotal;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  // Squad payment integration fields
  final String? squadTransactionRef;
  final String? squadGatewayRef;
  final String? paymentStatus;
  final String? escrowStatus;
  final DateTime? escrowReleaseDate;

  Order({
    required this.id,
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

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      addressId: json['address_id'],
      paymentMethodId: json['payment_method_id'],
      shippingMethod: json['shipping_method'],
      subtotal: json['subtotal'].toDouble(),
      shippingFee: json['shipping_fee'].toDouble(),
      total: json['total'].toDouble(),
      status: OrderStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      items: items ?? [],
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

  // Product and vendor information
  final String? productName;
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
    this.vendorId,
    this.vendorName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Extract product and vendor information if available
    String? productName;
    String? vendorId;
    String? vendorName;

    if (json['products'] != null) {
      final product = json['products'];
      productName = product['name'];
      vendorId = product['vendor_id'];

      if (product['vendors'] != null) {
        vendorName = product['vendors']['business_name'];
      }
    }

    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      selectedSize: json['selected_size'],
      selectedColor: json['selected_color'],
      createdAt: DateTime.parse(json['created_at']),
      productName: productName,
      vendorId: vendorId,
      vendorName: vendorName,
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
