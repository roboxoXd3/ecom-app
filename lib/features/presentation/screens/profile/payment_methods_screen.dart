import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const AddCardScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Credit/Debit Cards Section
          const Text(
            'Saved Cards',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Card Items
          _buildCardItem(
            cardType: 'Visa',
            lastFourDigits: '4242',
            expiryDate: '12/24',
            isDefault: true,
          ),
          const SizedBox(height: 12),
          _buildCardItem(
            cardType: 'Mastercard',
            lastFourDigits: '8888',
            expiryDate: '06/25',
            isDefault: false,
          ),

          const SizedBox(height: 32),

          // Other Payment Methods
          const Text(
            'Other Payment Methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // PayPal
          _buildPaymentMethodItem(
            icon: Icons.paypal,
            title: 'PayPal',
            subtitle: 'john.doe@example.com',
            isConnected: true,
          ),

          // Apple Pay
          _buildPaymentMethodItem(
            icon: Icons.apple,
            title: 'Apple Pay',
            subtitle: 'Not connected',
            isConnected: false,
          ),

          // Google Pay
          _buildPaymentMethodItem(
            icon: Icons.g_mobiledata,
            title: 'Google Pay',
            subtitle: 'Not connected',
            isConnected: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddCardScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardItem({
    required String cardType,
    required String lastFourDigits,
    required String expiryDate,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder:
                    (context) => [
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set as Default'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                onSelected: (value) {
                  // TODO: Handle card actions
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '**** **** **** $lastFourDigits',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expires: $expiryDate',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: TextButton(
        onPressed: () {
          // TODO: Handle connect/disconnect
        },
        child: Text(
          isConnected ? 'Disconnect' : 'Connect',
          style: TextStyle(
            color: isConnected ? Colors.red : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
