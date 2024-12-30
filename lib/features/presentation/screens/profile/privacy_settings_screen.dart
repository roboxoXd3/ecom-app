import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Observable variables for privacy settings
    final RxBool profileVisibility = true.obs;
    final RxBool activityStatus = true.obs;
    final RxBool showEmail = false.obs;
    final RxBool showPhone = false.obs;
    final RxBool locationSharing = true.obs;
    final RxBool dataCollection = true.obs;
    final RxBool personalisedAds = true.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        children: [
          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Control your privacy settings and manage how your information is displayed.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Visibility Section
          _buildSectionHeader('Profile Visibility'),
          Obx(
            () => SwitchListTile(
              title: const Text('Public Profile'),
              subtitle: const Text('Allow others to view your profile'),
              value: profileVisibility.value,
              onChanged: (value) => profileVisibility.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Activity Status'),
              subtitle: const Text('Show when you\'re active'),
              value: activityStatus.value,
              onChanged: (value) => activityStatus.value = value,
            ),
          ),

          const Divider(),

          // Contact Information Section
          _buildSectionHeader('Contact Information'),
          Obx(
            () => SwitchListTile(
              title: const Text('Show Email'),
              subtitle: const Text('Display email on your profile'),
              value: showEmail.value,
              onChanged: (value) => showEmail.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Show Phone Number'),
              subtitle: const Text('Display phone number on your profile'),
              value: showPhone.value,
              onChanged: (value) => showPhone.value = value,
            ),
          ),

          const Divider(),

          // Location & Data Section
          _buildSectionHeader('Location & Data'),
          Obx(
            () => SwitchListTile(
              title: const Text('Location Sharing'),
              subtitle: const Text('Share your location for better service'),
              value: locationSharing.value,
              onChanged: (value) => locationSharing.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Data Collection'),
              subtitle: const Text('Allow collection of usage data'),
              value: dataCollection.value,
              onChanged: (value) => dataCollection.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Personalised Ads'),
              subtitle: const Text('Show personalized advertisements'),
              value: personalisedAds.value,
              onChanged: (value) => personalisedAds.value = value,
            ),
          ),

          const Divider(),

          // Additional Privacy Options
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to blocked users screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Activity Log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to activity log screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download My Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement data download
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
