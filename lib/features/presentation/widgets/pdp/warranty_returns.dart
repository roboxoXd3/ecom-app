import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class WarrantyReturns extends StatelessWidget {
  final WarrantyInfo? warranty;
  final DeliveryInfo? deliveryInfo;

  const WarrantyReturns({super.key, this.warranty, this.deliveryInfo});

  @override
  Widget build(BuildContext context) {
    final hasWarranty = warranty != null;
    final hasReturnInfo = deliveryInfo != null;

    if (!hasWarranty && !hasReturnInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warranty & Returns',
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
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Warranty Information
                if (hasWarranty) ...[
                  _buildInfoRow(
                    Icons.verified_user,
                    'Warranty',
                    '${warranty!.duration} ${warranty!.type} warranty',
                    Colors.blue,
                    context,
                  ),
                  if (warranty!.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      warranty!.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                  if (hasReturnInfo) const SizedBox(height: 12),
                ],

                // Return Information
                if (hasReturnInfo) ...[
                  _buildInfoRow(
                    Icons.keyboard_return,
                    'Returns',
                    '${deliveryInfo!.returnWindowDays} days return policy',
                    Colors.green,
                    context,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.money_off,
                    'Return Conditions',
                    'Product must be unused and in original packaging',
                    Colors.orange,
                    context,
                  ),
                  if (deliveryInfo!.codEligible) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.money,
                      'COD Returns',
                      'Cash on Delivery returns accepted',
                      Colors.green,
                      context,
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // Policy Link
                InkWell(
                  onTap: () {
                    // Navigate to detailed policy page
                    _showPolicyDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.policy,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Detailed Policy',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Warranty & Return Policy',
            style: TextStyle(color: AppTheme.getTextPrimary(context)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warranty != null) ...[
                  Text(
                    'Warranty Terms:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${warranty!.duration} ${warranty!.type} warranty',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  Text(
                    '• Covers manufacturing defects',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  Text(
                    '• Does not cover physical damage or misuse',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  const SizedBox(height: 16),
                ],
                if (deliveryInfo != null) ...[
                  Text(
                    'Return Policy:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${deliveryInfo!.returnWindowDays} days return window',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  Text(
                    '• Product must be unused and in original packaging',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  Text(
                    '• Return shipping may be charged',
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  ),
                  if (deliveryInfo!.codEligible)
                    Text(
                      '• COD returns accepted',
                      style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
