import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/address_controller.dart';
import '../../controllers/payment_method_controller.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final orderController = Get.find<OrderController>();
  final addressController = Get.find<AddressController>();
  final paymentController = Get.find<PaymentMethodController>();

  OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = orderController.orders.firstWhere((o) => o.id == orderId);
    final address = addressController.addresses.firstWhere(
      (a) => a.id == order.addressId,
    );
    final paymentMethod = paymentController.paymentMethods.firstWhere(
      (p) => p.id == order.paymentMethodId,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        order.status == 'delivered'
                            ? Icons.check_circle
                            : Icons.local_shipping,
                        color:
                            order.status == 'delivered'
                                ? Colors.green
                                : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.status.capitalizeFirst!,
                        style: TextStyle(
                          color:
                              order.status == 'delivered'
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (order.status != 'delivered') ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Order Date',
                    order.createdAt.toString().split(' ')[0],
                  ),
                  _buildDetailRow('Order ID', '#${order.id}'),
                  _buildDetailRow('Payment Method', paymentMethod.displayName),
                  _buildDetailRow(
                    'Shipping Address',
                    '${address.addressLine1}, ${address.city}, ${address.state} ${address.zip}',
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
