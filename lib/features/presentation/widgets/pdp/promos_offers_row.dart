import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class PromosOffersRow extends StatelessWidget {
  final List<ProductOffer> offers;

  const PromosOffersRow({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offers & Promotions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: offers.length,
              itemBuilder: (context, index) {
                return _buildOfferChip(offers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferChip(ProductOffer offer) {
    Color chipColor;
    IconData chipIcon;

    switch (offer.type) {
      case 'bank':
        chipColor = Colors.blue;
        chipIcon = Icons.account_balance;
        break;
      case 'delivery':
        chipColor = Colors.green;
        chipIcon = Icons.local_shipping;
        break;
      case 'cod':
        chipColor = Colors.orange;
        chipIcon = Icons.money;
        break;
      case 'coupon':
        chipColor = AppTheme.primaryColor;
        chipIcon = Icons.local_offer;
        break;
      case 'timer':
        chipColor = Colors.red;
        chipIcon = Icons.timer;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.local_offer;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            offer.description,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (offer.type == 'timer' && offer.expiryDate != null) ...[
            const SizedBox(width: 6),
            _buildCountdownTimer(offer.expiryDate!),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return const Text(
        'EXPIRED',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${hours}h ${minutes}m',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
