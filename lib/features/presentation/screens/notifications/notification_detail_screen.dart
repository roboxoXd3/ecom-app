import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'notification_type.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final String? imageUrl;
  final String? actionButtonText;
  final VoidCallback? onActionButtonPressed;

  const NotificationDetailScreen({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.imageUrl,
    this.actionButtonText,
    this.onActionButtonPressed,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement delete notification
              Navigator.pop(context, 'delete');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(time),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Message content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            // Image if available
            if (imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Additional details for specific notification types
            if (type == NotificationType.order) _buildOrderDetails(),

            if (type == NotificationType.promo) _buildPromoDetails(),

            // Action button if available
            if (actionButtonText != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onActionButtonPressed,
                    child: Text(actionButtonText!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Order Number', '#12345'),
          _buildDetailRow('Order Date', '2024-03-20'),
          _buildDetailRow('Status', 'Delivered'),
          _buildDetailRow('Tracking Number', 'TRK123456789'),
        ],
      ),
    );
  }

  Widget _buildPromoDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promotion Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Discount', '50% OFF'),
          _buildDetailRow('Valid Until', '2024-03-31'),
          _buildDetailRow('Promo Code', 'SUMMER50'),
          _buildDetailRow('Terms', 'Valid on selected items only'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
