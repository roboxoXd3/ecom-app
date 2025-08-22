import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../../data/models/order_status.dart'; // ignore: unused_import

class MyOrdersScreen extends StatelessWidget {
  final orderController = Get.find<OrderController>();

  MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh orders when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchUserOrders();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderController.fetchUserOrders(),
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.orders.isEmpty) {
          return const Center(child: Text('No orders yet'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await orderController.fetchUserOrders();
          },
          child: ListView.builder(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  '0xFF${order.status.colorHex.substring(1)}',
                                ),
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(
                                  int.parse(
                                    '0xFF${order.status.colorHex.substring(1)}',
                                  ),
                                ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              order.status.displayName,
                              style: TextStyle(
                                color: Color(
                                  int.parse(
                                    '0xFF${order.status.colorHex.substring(1)}',
                                  ),
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
          ),
        );
      }),
    );
  }
}
