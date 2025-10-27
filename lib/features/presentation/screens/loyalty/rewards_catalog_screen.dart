import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/loyalty_controller.dart';

class RewardsCatalogScreen extends StatelessWidget {
  const RewardsCatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoyaltyController controller = Get.find<LoyaltyController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Catalog'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Obx(() {
            final account = controller.loyaltyAccount.value;
            if (account == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(16),
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.white,
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${account.pointsBalance} points available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingRewards.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = controller.rewards;
        if (rewards.isEmpty) {
          return const Center(
            child: Text('No rewards available at the moment'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadRewards(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return _buildRewardCard(reward, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildRewardCard(reward, LoyaltyController controller) {
    final canAfford = controller.canAffordReward(reward.pointsRequired);
    final isAvailable = canAfford && reward.canRedeemMore;

    return Stack(
      children: [
        Card(
          elevation: isAvailable ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isAvailable
                    ? BorderSide(color: Colors.green.shade300, width: 2)
                    : BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.6,
            child: InkWell(
              onTap:
                  isAvailable
                      ? () => _showRedeemDialog(reward, controller)
                      : null,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Header with reward type
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isAvailable
                                ? [
                                  Colors.purple.shade300,
                                  Colors.purple.shade500,
                                ]
                                : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            reward.rewardTypeDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Available badge
                        if (isAvailable)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? null : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (reward.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            reward.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isAvailable
                                      ? Colors.grey[600]
                                      : Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Points required
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                canAfford
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  canAfford
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars,
                                color:
                                    canAfford
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.pointsRequired} pts',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      canAfford
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status messages
                        if (!canAfford) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 12,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Need more points',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!reward.canRedeemMore) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.block,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Max redemptions reached',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isAvailable) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Ready to redeem',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Lock icon overlay for unavailable rewards
        if (!isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.1),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showRedeemDialog(reward, LoyaltyController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Redeem Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reward.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(reward.rewardValue),
            const SizedBox(height: 16),
            Text(
              'Cost: ${reward.pointsRequired} points',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (reward.minimumOrderAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Minimum order: \$${reward.minimumOrderAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.redeemReward(reward.id);
              if (success) {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Success!'),
                    content: const Text(
                      'Your voucher has been generated. Check "My Vouchers" to view it.',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}
