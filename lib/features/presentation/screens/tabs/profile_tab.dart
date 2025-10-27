import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';
import '../profile/my_orders_screen.dart';
import '../profile/wishlist_screen.dart';
import '../profile/shipping_address_screen.dart';
import '../profile/payment_methods_screen.dart';
import '../profile/help_support_screen.dart';
import '../profile/settings_screen.dart';
import '../vendor/followed_vendors_screen.dart';
import '../vendor/vendors_list_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // ✅ ADD THIS LINE - Refresh user data when profile tab is accessed
    authController.updateUserData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              authController.userName.value.isNotEmpty
                  ? authController.userName.value
                  : 'User', // Simplified fallback
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Obx(
            () => Text(
              authController.userEmail.value.isNotEmpty
                  ? authController.userEmail.value
                  : 'No email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),

          // Profile Options
          _buildProfileOption(
            icon: Icons.shopping_bag,
            title: 'My Orders',
            onTap: () => Get.to(() => MyOrdersScreen()),
          ),
          _buildProfileOption(
            icon: Icons.favorite,
            title: 'Wishlist',
            onTap: () => Get.to(() => WishlistScreen()),
          ),
          _buildProfileOption(
            icon: Icons.location_on,
            title: 'Shipping Address',
            onTap: () => Get.to(() => ShippingAddressScreen()),
          ),
          _buildProfileOption(
            icon: Icons.payment,
            title: 'Payment Methods',
            onTap: () => Get.to(() => PaymentMethodsScreen()),
          ),
          _buildProfileOption(
            icon: Icons.storefront,
            title: 'Browse Vendors',
            onTap: () => Get.to(() => const VendorsListScreen()),
          ),
          _buildProfileOption(
            icon: Icons.store,
            title: 'Followed Vendors',
            onTap: () => Get.to(() => const FollowedVendorsScreen()),
          ),
          _buildProfileOption(
            icon: Icons.card_giftcard,
            title: 'Loyalty & Rewards',
            onTap: () => Get.toNamed(AppRoutes.loyaltyHome),
          ),
          _buildProfileOption(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () => Get.to(() => HelpSupportScreen()),
          ),
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              try {
                await authController.logout();
                Get.offAll(() => const LoginScreen());
              } catch (e) {
                debugPrint('Logout error: $e');
              }
            },
            isDestructive: true,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
