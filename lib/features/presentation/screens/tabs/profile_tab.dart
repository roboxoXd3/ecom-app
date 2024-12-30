import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';
import '../profile/my_orders_screen.dart';
import '../profile/wishlist_screen.dart';
import '../profile/shipping_address_screen.dart';
import '../profile/payment_methods_screen.dart';
import '../profile/help_support_screen.dart';
import '../profile/settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final user = Supabase.instance.client.auth.currentUser;
    final userMetadata = user?.userMetadata;
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
          Text(
            userMetadata?['full_name'] ?? 'User',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'No email',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Profile Options
          _buildProfileOption(
            icon: Icons.shopping_bag,
            title: 'My Orders',
            onTap: () => Get.to(() => const MyOrdersScreen()),
          ),
          _buildProfileOption(
            icon: Icons.favorite,
            title: 'Wishlist',
            onTap: () => Get.to(() => const WishlistScreen()),
          ),
          _buildProfileOption(
            icon: Icons.location_on,
            title: 'Shipping Address',
            onTap: () => Get.to(() => const ShippingAddressScreen()),
          ),
          _buildProfileOption(
            icon: Icons.payment,
            title: 'Payment Methods',
            onTap: () => Get.to(() => const PaymentMethodsScreen()),
          ),
          _buildProfileOption(
            icon: Icons.analytics_outlined,
            title: 'Search Analytics',
            onTap: () => Get.toNamed('/analytics'),
          ),
          _buildProfileOption(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () => Get.to(() => const HelpSupportScreen()),
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
