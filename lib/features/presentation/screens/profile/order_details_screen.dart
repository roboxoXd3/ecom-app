import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrderDetailsScreen extends StatelessWidget {
  final int orderId;
  final bool isDelivered;
  final String date;
  final double total;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.isDelivered,
    required this.date,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
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
                        isDelivered ? Icons.check_circle : Icons.local_shipping,
                        color:
                            isDelivered ? Colors.green : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDelivered ? 'Delivered' : 'In Progress',
                        style: TextStyle(
                          color:
                              isDelivered
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!isDelivered) ...[
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
                  _buildDetailRow('Order Date', date),
                  _buildDetailRow('Order ID', '#$orderId'),
                  _buildDetailRow('Payment Method', 'Credit Card (**** 1234)'),
                  _buildDetailRow(
                    'Shipping Address',
                    '123 Main St, New York, NY 10001',
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
                  // Sample items - replace with actual order items
                  _buildOrderItem(
                    'Product 1',
                    'Size: M, Color: Black',
                    2,
                    49.99,
                  ),
                  const Divider(),
                  _buildOrderItem(
                    'Product 2',
                    'Size: L, Color: Blue',
                    1,
                    39.99,
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
                  _buildPriceRow('Subtotal', total - 10),
                  _buildPriceRow('Shipping', 10.00),
                  const Divider(),
                  _buildPriceRow('Total', total, isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Support Button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement support
            },
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
          '\$${(price * quantity).toStringAsFixed(2)}',
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
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
