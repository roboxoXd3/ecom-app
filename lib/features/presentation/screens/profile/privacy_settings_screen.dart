import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'delete_account_screen.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        'Manage your account privacy and data settings.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Danger Zone - KEEP THIS SAFE! Critical feature!
          _buildSectionHeader('Danger Zone'),
          Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Deleting your account is permanent and cannot be undone. '
                          'All your personal data will be removed.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Colors.red.shade700,
                  ),
                  title: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.red.shade700,
                  ),
                  onTap: () => Get.to(() => const DeleteAccountScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
