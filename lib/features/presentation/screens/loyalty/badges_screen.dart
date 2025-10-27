import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/loyalty_controller.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoyaltyController controller = Get.find<LoyaltyController>();

    // Load badges when screen is opened
    controller.loadBadges();

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements & Badges')),
      body: Obx(() {
        if (controller.isLoadingBadges.value && controller.badges.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final earnedBadges = controller.earnedBadges;
        final availableBadges = controller.availableBadges;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (earnedBadges.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Earned Badges (${earnedBadges.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildBadgeGrid(earnedBadges, true),
              ],
              if (availableBadges.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Available Badges (${availableBadges.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildBadgeGrid(availableBadges, false),
              ],
              if (earnedBadges.isEmpty && availableBadges.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No badges available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBadgeGrid(List badges, bool isEarned) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(badge, isEarned);
      },
    );
  }

  Widget _buildBadgeCard(badge, bool isEarned) {
    return Card(
      elevation: isEarned ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors:
                isEarned
                    ? [Colors.amber.shade300, Colors.amber.shade100]
                    : [Colors.grey.shade200, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEarned ? Icons.emoji_events : Icons.emoji_events_outlined,
              size: 64,
              color: isEarned ? Colors.amber.shade700 : Colors.grey,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? Colors.black87 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge.description != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  badge.description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isEarned ? Colors.black54 : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!isEarned) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: badge.progress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.progressDisplayText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isEarned && badge.earnedAt != null) ...[
              Text(
                'Earned ${_formatDate(badge.earnedAt!)}',
                style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
              ),
            ],
            if (badge.bonusPoints > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEarned ? Colors.green : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${badge.bonusPoints} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
