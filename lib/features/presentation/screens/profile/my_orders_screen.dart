import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../controllers/order_controller.dart';

class MyOrdersScreen extends StatelessWidget {
  final orderController = Get.find<OrderController>();

  MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchUserOrders();
    });

    return Scaffold(
      backgroundColor: AppTheme.getSurface(context),
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02 * 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => orderController.fetchUserOrders(),
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (orderController.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64,
                    color: AppTheme.getTextSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                    letterSpacing: -0.02 * 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your order history will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => orderController.fetchUserOrders(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: orderController.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orderController.orders[index];
              return _OrderCard(order: order);
            },
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(
      int.parse('0xFF${order.status.colorHex.substring(1)}'),
    );
    final itemCount = order.items.length;
    final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed('/order-details', arguments: order.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.getBorder(context).withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Icon(_statusIcon(order.status),
                        size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.displayOrderNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: -0.02 * 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product thumbnails row
              if (order.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    children: [
                      ...order.items.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ItemThumbnail(item: item),
                          )),
                      if (itemCount > 3)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.getBorder(context)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${itemCount - 3}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                    ],
                  ),
                ),

              // Item names summary
              if (order.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Text(
                    _buildItemsSummary(order.items),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(context),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Footer: date, qty, total
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextSecondary(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '$totalQty ${totalQty == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => Text(
                        CurrencyUtils.formatAmount(order.total),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: -0.02 * 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildItemsSummary(List<OrderItem> items) {
    final names = items
        .where((i) => i.productName != null && i.productName!.isNotEmpty)
        .map((i) => i.productName!)
        .toList();
    if (names.isEmpty) return '${items.length} product${items.length == 1 ? '' : 's'}';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} & ${names[1]}';
    return '${names[0]}, ${names[1]} +${names.length - 2} more';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule_rounded;
      case OrderStatus.processing:
        return Icons.settings_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.completed:
        return Icons.done_all_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
      case OrderStatus.failed:
        return Icons.error_rounded;
      case OrderStatus.returned:
        return Icons.keyboard_return_rounded;
    }
  }
}

class _ItemThumbnail extends StatelessWidget {
  final OrderItem item;
  const _ItemThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: item.productImage != null && item.productImage!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.productImage!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.getBorder(context).withValues(alpha: 0.08),
                ),
                errorWidget: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppTheme.getBorder(context).withValues(alpha: 0.08),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 20,
        color: AppTheme.getTextSecondary(context),
      ),
    );
  }
}
