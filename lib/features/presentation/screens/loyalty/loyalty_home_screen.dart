import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/loyalty_controller.dart';
import 'rewards_catalog_screen.dart';
import 'my_vouchers_screen.dart';
import 'transaction_history_screen.dart';
import 'badges_screen.dart';

class LoyaltyHomeScreen extends StatelessWidget {
  const LoyaltyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoyaltyController controller = Get.put(LoyaltyController());

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Rewards'), elevation: 0),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.loyaltyAccount.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final account = controller.loyaltyAccount.value;
        if (account == null) {
          return const Center(
            child: Text('Unable to load loyalty information'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshBalance(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Points Balance Card
                _buildPointsBalanceCard(account),

                const SizedBox(height: 16),

                // Tier Progress Card
                _buildTierProgressCard(account),

                const SizedBox(height: 16),

                // Quick Actions
                _buildQuickActions(controller),

                const SizedBox(height: 24),

                // Recent Transactions Preview
                _buildRecentTransactions(controller),

                const SizedBox(height: 24),

                // Earned Badges Preview
                _buildBadgesPreview(controller),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPointsBalanceCard(account) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTierColor(account.tier, context),
                  _getTierGradientColor(account.tier, context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${account.tierDisplayName} Member',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _getTierIcon(account.tier),
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${account.pointsBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${account.lifetimePoints} lifetime points earned',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  account.tierBenefits,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTierProgressCard(account) {
    if (account.nextTier == null) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to ${account.nextTier}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${account.tierProgress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getTierColor(account.tier, context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: account.tierProgress / 100,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTierColor(account.tier, context),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${account.pointsToNextTier} more points needed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickActions(LoyaltyController controller) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.card_giftcard,
                        title: 'Rewards',
                        subtitle: 'Redeem points',
                        color: const Color(0xFF10B981),
                        onTap: () => Get.to(() => const RewardsCatalogScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.receipt_long,
                        title: 'Vouchers',
                        subtitle: 'My vouchers',
                        color: const Color(0xFF0D9488),
                        onTap: () => Get.to(() => const MyVouchersScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.history,
                        title: 'History',
                        subtitle: 'View transactions',
                        color: const Color(0xFFD97706),
                        onTap:
                            () =>
                                Get.to(() => const TransactionHistoryScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.emoji_events,
                        title: 'Badges',
                        subtitle: 'Achievements',
                        color: const Color(0xFF059669),
                        onTap: () => Get.to(() => const BadgesScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(LoyaltyController controller) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.loadTransactionHistory();
                        Get.to(() => const TransactionHistoryScreen());
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your transaction history for full details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildBadgesPreview(LoyaltyController controller) {
    return Builder(
      builder:
          (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.loadBadges();
                        Get.to(() => const BadgesScreen());
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Earn badges by completing milestones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Color _getTierColor(String tier, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (tier.toLowerCase()) {
      case 'bronze':
        return isDark ? const Color(0xFFD4915D) : const Color(0xFFB87333);
      case 'silver':
        return isDark ? const Color(0xFFE8E8E8) : const Color(0xFF616161);
      case 'gold':
        return isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706);
      case 'platinum':
        return isDark ? const Color(0xFF00CED1) : const Color(0xFF10B981);
      default:
        return isDark ? const Color(0xFFD4915D) : const Color(0xFFB87333);
    }
  }

  Color _getTierGradientColor(String tier, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (tier.toLowerCase()) {
      case 'bronze':
        return isDark ? const Color(0xFFB87333) : const Color(0xFF9B5C2A);
      case 'silver':
        return isDark ? const Color(0xFFC0C0C0) : const Color(0xFF424242);
      case 'gold':
        return isDark ? const Color(0xFFFFB300) : const Color(0xFFFBBF24);
      case 'platinum':
        return isDark ? const Color(0xFF00A8B5) : const Color(0xFF059669);
      default:
        return isDark ? const Color(0xFFB87333) : const Color(0xFF9B5C2A);
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.workspace_premium;
      case 'gold':
        return Icons.workspace_premium;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.workspace_premium;
    }
  }
}
