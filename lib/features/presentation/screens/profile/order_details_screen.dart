import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/address_controller.dart';
import '../../../data/models/order_status.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final orderController = Get.find<OrderController>();
  final addressController = Get.find<AddressController>();

  OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Refresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchUserOrders();
      addressController.fetchAddresses();
    });

    return Obx(() {
      // Find the order
      final order = orderController.orders.firstWhereOrNull(
        (o) => o.id == orderId,
      );
      if (order == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Order Details')),
          body: const Center(child: Text('Order not found')),
        );
      }

      // Find the address
      final address = addressController.addresses.firstWhereOrNull(
        (a) => a.id == order.addressId,
      );

      return Scaffold(
        appBar: AppBar(title: Text('Order #${order.id.substring(0, 8)}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          color: Color(
                            int.parse(
                              '0xFF${order.status.colorHex.substring(1)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.status.displayName,
                          style: TextStyle(
                            color: Color(
                              int.parse(
                                '0xFF${order.status.colorHex.substring(1)}',
                              ),
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.status.description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (!order.status.isFinal) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _getProgressValue(order.status),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(
                            int.parse(
                              '0xFF${order.status.colorHex.substring(1)}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estimated Delivery: 2-3 Business Days',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Order Date',
                      order.createdAt.toString().split(' ')[0],
                    ),
                    _buildDetailRow('Order ID', '#${order.id}'),
                    _buildDetailRow(
                      'Payment Method',
                      order.paymentMethodDisplayName,
                    ),
                    _buildDetailRow(
                      'Shipping Address',
                      address != null
                          ? '${address.addressLine1}, ${address.city}, ${address.state} ${address.zip}'
                          : 'Address not found',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...order.items.map(
                      (item) => Column(
                        children: [
                          _buildOrderItem(
                            'Product ${item.productId}', // TODO: Get actual product name
                            'Size: ${item.selectedSize}, Color: ${item.selectedColor}',
                            item.quantity,
                            item.price,
                          ),
                          if (item != order.items.last) const Divider(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceRow('Subtotal', order.subtotal),
                    _buildPriceRow('Shipping', order.shippingFee),
                    const Divider(),
                    _buildPriceRow('Total', order.total, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Support Button
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/help-support'),
              icon: const Icon(Icons.support_agent),
              label: const Text('Need Help?'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.processing:
        return Icons.settings;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.failed:
        return Icons.error;
      case OrderStatus.returned:
        return Icons.keyboard_return;
    }
  }

  double _getProgressValue(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.2;
      case OrderStatus.processing:
        return 0.4;
      case OrderStatus.shipped:
        return 0.7;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    String name,
    String variant,
    int quantity,
    double price,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                variant,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantity: $quantity',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Text(
          '₹${(price * quantity).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
