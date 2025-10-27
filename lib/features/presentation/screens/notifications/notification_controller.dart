import 'package:get/get.dart';
import 'notification_type.dart';

class NotificationController extends GetxController {
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with dummy data
    notifications.addAll([
      NotificationItem(
        id: '1',
        type: NotificationType.order,
        title: 'Order Delivered',
        message: 'Your order #12345 has been delivered successfully.',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.promo,
        title: 'Flash Sale!',
        message: 'Don\'t miss out on our 24-hour flash sale. Up to 70% off!',
        time: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      // Add more notifications as needed
    ]);
    _updateUnreadCount();
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    notifications.value =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    _updateUnreadCount();
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
