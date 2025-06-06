import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_card_screen.dart';
import '../../controllers/payment_method_controller.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  final paymentMethodController = Get.put(PaymentMethodController());

  PaymentMethodsScreen({super.key});

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
      body: Obx(() {
        if (paymentMethodController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Saved Cards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (paymentMethodController.paymentMethods.isEmpty)
              const Center(child: Text('No cards added yet'))
            else
              ...paymentMethodController.paymentMethods.map((card) {
                return Column(
                  children: [
                    _buildCardItem(
                      cardType: card.cardBrand ?? card.type,
                      cardHolderName: card.displayName,
                      lastFourDigits: card.last4 ?? '****',
                      expiryDate: card.expiryDate,
                      isDefault: card.isDefault,
                      onDelete: () => _deleteCard(card.id),
                      onSetDefault:
                          () => paymentMethodController.setDefaultPaymentMethod(
                            card.id,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

            // Rest of the payment methods...
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddCardScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteCard(String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              paymentMethodController.deletePaymentMethod(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required String cardType,
    required String cardHolderName,
    required String lastFourDigits,
    required String expiryDate,
    required bool isDefault,
    required Function() onDelete,
    required Function() onSetDefault,
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
            cardHolderName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2,
            ),
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
}
