import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/loyalty_controller.dart';

class MyVouchersScreen extends StatelessWidget {
  const MyVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoyaltyController controller = Get.find<LoyaltyController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Vouchers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Used'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.loadVouchers(),
          child: Obx(() {
            if (controller.isLoadingVouchers.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildVoucherList(
                  controller.getVouchersByStatus('active'),
                  'No active vouchers',
                  context,
                ),
                _buildVoucherList(
                  controller.getVouchersByStatus('used'),
                  'No used vouchers',
                  context,
                ),
                _buildVoucherList(
                  controller.getVouchersByStatus('expired'),
                  'No expired vouchers',
                  context,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVoucherList(
    List vouchers,
    String emptyMessage,
    BuildContext context,
  ) {
    if (vouchers.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return _buildVoucherCard(voucher, context);
      },
    );
  }

  Widget _buildVoucherCard(voucher, BuildContext context) {
    final isActive = voucher.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors:
                isActive
                    ? [
                      const Color(0xFF10B981).withOpacity(0.1),
                      Theme.of(context).colorScheme.surface,
                    ]
                    : [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    voucher.rewardName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? const Color(0xFF10B981)
                            : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    voucher.statusDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              voucher.discountDisplayValue,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    isActive
                        ? const Color(0xFF10B981)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    voucher.voucherCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (isActive)
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: voucher.voucherCode),
                        );
                        Get.snackbar(
                          'Copied',
                          'Voucher code copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      tooltip: 'Copy code',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (voucher.minimumOrderAmount > 0) ...[
              Text(
                'Min. order: \$${voucher.minimumOrderAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive
                      ? 'Expires in ${voucher.daysUntilExpiry} days'
                      : 'Expired',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isActive
                            ? const Color(0xFFF59E0B)
                            : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Valid until ${_formatDate(voucher.expiresAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
