import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class KeyHighlightsStrip extends StatelessWidget {
  final List<ProductHighlight> highlights;

  const KeyHighlightsStrip({super.key, required this.highlights});

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: highlights.length,
              itemBuilder: (context, index) {
                return _buildHighlightChip(highlights[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChip(ProductHighlight highlight) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlight.iconUrl != null) ...[
            // If we have a custom icon URL, we could load it here
            // For now, using default icons based on common feature types
            Icon(
              _getIconForHighlight(highlight.label),
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            highlight.label,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForHighlight(String label) {
    final lowerLabel = label.toLowerCase();

    if (lowerLabel.contains('battery') || lowerLabel.contains('power')) {
      return Icons.battery_full;
    } else if (lowerLabel.contains('display') ||
        lowerLabel.contains('lcd') ||
        lowerLabel.contains('screen')) {
      return Icons.monitor;
    } else if (lowerLabel.contains('glass') ||
        lowerLabel.contains('tempered')) {
      return Icons.shield;
    } else if (lowerLabel.contains('weight') ||
        lowerLabel.contains('kg') ||
        lowerLabel.contains('capacity')) {
      return Icons.scale;
    } else if (lowerLabel.contains('auto') ||
        lowerLabel.contains('automatic')) {
      return Icons.auto_mode;
    } else if (lowerLabel.contains('water') || lowerLabel.contains('proof')) {
      return Icons.water_drop;
    } else if (lowerLabel.contains('wireless') ||
        lowerLabel.contains('bluetooth')) {
      return Icons.bluetooth;
    } else if (lowerLabel.contains('fast') || lowerLabel.contains('quick')) {
      return Icons.speed;
    } else if (lowerLabel.contains('premium') ||
        lowerLabel.contains('quality')) {
      return Icons.star;
    } else if (lowerLabel.contains('durable') ||
        lowerLabel.contains('strong')) {
      return Icons.security;
    } else {
      return Icons.check_circle;
    }
  }
}
