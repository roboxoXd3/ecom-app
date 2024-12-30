import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'about_us_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Observable variables for settings
    final RxBool pushNotifications = true.obs;
    final RxBool emailNotifications = true.obs;
    final RxBool darkMode = false.obs;
    final RxString selectedLanguage = 'English'.obs;
    final RxString selectedCurrency = 'USD'.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account Settings Section
          _buildSectionHeader('Account Settings'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const EditProfileScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const ChangePasswordScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const PrivacySettingsScreen()),
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Obx(
            () => SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: pushNotifications.value,
              onChanged: (value) => pushNotifications.value = value,
            ),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email notifications'),
              value: emailNotifications.value,
              onChanged: (value) => emailNotifications.value = value,
            ),
          ),

          const Divider(),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          Obx(
            () => SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: darkMode.value,
              onChanged: (value) {
                darkMode.value = value;
                // TODO: Implement theme switching
              },
            ),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Obx(() => Text(selectedLanguage.value)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageSelector(context, selectedLanguage);
            },
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Obx(() => Text(selectedCurrency.value)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCurrencySelector(context, selectedCurrency);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const AboutUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const TermsOfServiceScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const PrivacyPolicyScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
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
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, RxString selectedLanguage) {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(languages[index]),
                trailing:
                    languages[index] == selectedLanguage.value
                        ? const Icon(Icons.check, color: AppTheme.primaryColor)
                        : null,
                onTap: () {
                  selectedLanguage.value = languages[index];
                  Navigator.pop(context);
                },
              );
            },
          ),
    );
  }

  void _showCurrencySelector(BuildContext context, RxString selectedCurrency) {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY'];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(currencies[index]),
                trailing:
                    currencies[index] == selectedCurrency.value
                        ? const Icon(Icons.check, color: AppTheme.primaryColor)
                        : null,
                onTap: () {
                  selectedCurrency.value = currencies[index];
                  Navigator.pop(context);
                },
              );
            },
          ),
    );
  }
}
