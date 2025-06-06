import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';

class MyOrdersScreen extends StatelessWidget {
  final orderController = Get.find<OrderController>();

  MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.orders.isEmpty) {
          return const Center(child: Text('No orders yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orderController.orders.length,
          itemBuilder: (context, index) {
            final order = orderController.orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${order.createdAt.toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () => Get.toNamed(
                            '/order-details',
                            arguments: order.id,
                          ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
