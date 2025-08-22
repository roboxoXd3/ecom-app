import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'about_us_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../../controllers/currency_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get currency controller
    final CurrencyController currencyController =
        Get.find<CurrencyController>();

    // Observable variables for settings
    final RxBool pushNotifications = true.obs;
    final RxBool emailNotifications = true.obs;
    final RxBool darkMode = false.obs;
    final RxString selectedLanguage = 'English'.obs;

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
          Obx(
            () => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currencyController.getCurrencySymbol(
                    currencyController.selectedCurrency.value,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              title: const Text('Currency'),
              subtitle: Text(
                '${currencyController.selectedCurrency.value} - ${currencyController.getCurrencyName(currencyController.selectedCurrency.value)}',
              ),
              trailing:
                  currencyController.isLoading.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Quick Access',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
              onTap:
                  currencyController.isLoading.value
                      ? null
                      : () {
                        _showCurrencySelector(context, currencyController);
                      },
            ),
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

  void _showCurrencySelector(
    BuildContext context,
    CurrencyController currencyController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => currencyController.refreshCurrencyData(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh currencies',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (currencyController.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (currencyController.error.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              currencyController.error.value,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () => currencyController.loadCurrencyData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: currencyController.supportedCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency =
                          currencyController.supportedCurrencies[index];
                      final isSelected =
                          currency['code'] ==
                          currencyController.selectedCurrency.value;

                      return ListTile(
                        title: Text(
                          '${currency['name']} (${currency['code']})',
                        ),
                        subtitle: Text(currency['symbol']),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: AppTheme.primaryColor,
                                )
                                : null,
                        onTap: () {
                          currencyController.updateCurrency(currency['code']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
