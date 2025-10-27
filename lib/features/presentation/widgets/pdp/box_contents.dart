import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BoxContents extends StatelessWidget {
  final List<String> contents;

  const BoxContents({super.key, required this.contents});

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s in the Box',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.getBorder(context)),
            ),
            child: Column(
              children:
                  contents
                      .map((item) => _buildContentItem(item, context))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(String item, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),
          Icon(
            _getIconForItem(item),
            size: 20,
            color: AppTheme.getTextSecondary(context),
          ),
        ],
      ),
    );
  }

  IconData _getIconForItem(String item) {
    final lowerItem = item.toLowerCase();

    if (lowerItem.contains('manual') ||
        lowerItem.contains('guide') ||
        lowerItem.contains('instruction')) {
      return Icons.menu_book;
    } else if (lowerItem.contains('cable') ||
        lowerItem.contains('wire') ||
        lowerItem.contains('cord')) {
      return Icons.cable;
    } else if (lowerItem.contains('charger') || lowerItem.contains('adapter')) {
      return Icons.power;
    } else if (lowerItem.contains('battery') || lowerItem.contains('cell')) {
      return Icons.battery_full;
    } else if (lowerItem.contains('box') || lowerItem.contains('package')) {
      return Icons.inventory_2;
    } else if (lowerItem.contains('warranty') ||
        lowerItem.contains('certificate')) {
      return Icons.verified;
    } else if (lowerItem.contains('tool') ||
        lowerItem.contains('screwdriver')) {
      return Icons.build;
    } else if (lowerItem.contains('case') ||
        lowerItem.contains('cover') ||
        lowerItem.contains('pouch')) {
      return Icons.work_outline;
    } else if (lowerItem.contains('cloth') || lowerItem.contains('cleaning')) {
      return Icons.cleaning_services;
    } else {
      return Icons.inventory;
    }
  }
}
