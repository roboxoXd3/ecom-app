import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get/get.dart';
import 'notification_detail_screen.dart';
import 'notification_controller.dart';
import 'notification_type.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notificationController.markAllAsRead(),
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          children: [
            _buildDateGroup(
              'Today',
              notificationController.notifications
                  .where((n) => _isToday(n.time))
                  .map(
                    (n) => _NotificationItem(
                      id: n.id,
                      type: n.type,
                      title: n.title,
                      message: n.message,
                      time: n.time,
                      isRead: n.isRead,
                      notificationController: notificationController,
                    ),
                  )
                  .toList(),
            ),
            _buildDateGroup(
              'Yesterday',
              notificationController.notifications
                  .where((n) => _isYesterday(n.time))
                  .map(
                    (n) => _NotificationItem(
                      id: n.id,
                      type: n.type,
                      title: n.title,
                      message: n.message,
                      time: n.time,
                      isRead: n.isRead,
                      notificationController: notificationController,
                    ),
                  )
                  .toList(),
            ),
            _buildDateGroup(
              'This Week',
              notificationController.notifications
                  .where((n) => _isThisWeek(n.time))
                  .map(
                    (n) => _NotificationItem(
                      id: n.id,
                      type: n.type,
                      title: n.title,
                      message: n.message,
                      time: n.time,
                      isRead: n.isRead,
                      notificationController: notificationController,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime time) {
    final now = DateTime.now();
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }

  bool _isYesterday(DateTime time) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day;
  }

  bool _isThisWeek(DateTime time) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return time.isAfter(weekAgo) && !_isToday(time) && !_isYesterday(time);
  }

  Widget _buildDateGroup(String title, List<_NotificationItem> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...notifications,
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationController notificationController;

  const _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.notificationController,
  });

  IconData get _icon {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.account:
        return Icons.person_outline;
    }
  }

  Color get _iconColor {
    switch (type) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.promo:
        return Colors.orange;
      case NotificationType.account:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Get.to(
          () => NotificationDetailScreen(
            type: type,
            title: title,
            message: message,
            time: time,
            actionButtonText:
                type == NotificationType.order
                    ? 'Track Order'
                    : type == NotificationType.promo
                    ? 'Be Smart'
                    : null,
            onActionButtonPressed: () {
              // TODO: Handle action button press
              Get.back();
            },
          ),
        );

        if (result == 'delete') {
          // TODO: Handle notification deletion
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey[600], height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(time),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Mark as read'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
              onSelected: (value) {
                if (value == 'read') {
                  notificationController.markAsRead(id);
                } else if (value == 'delete') {
                  notificationController.deleteNotification(id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
