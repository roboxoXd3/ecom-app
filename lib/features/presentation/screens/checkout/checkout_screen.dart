import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../controllers/address_controller.dart';
import '../../controllers/order_controller.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final addressController = Get.find<AddressController>();
    final orderController = Get.find<OrderController>();
    final selectedAddressId = ''.obs;

    void proceedToPayment() {
      // Placeholder payment logic - replace with your preferred payment gateway
      Get.dialog(
        AlertDialog(
          title: const Text('Payment'),
          content: const Text(
            'Payment functionality will be implemented with your preferred payment gateway.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                SnackbarUtils.showSuccess('Order placed successfully!');
                // Clear cart and navigate to orders
                cartController.clearCart();
                Get.offAllNamed('/');
              },
              child: const Text('Simulate Payment'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (addressController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (addressController.addresses.isEmpty) {
                return Center(
                  child: TextButton(
                    onPressed: () => Get.toNamed('/add-address'),
                    child: const Text('Add New Address'),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: addressController.addresses.length,
                itemBuilder: (context, index) {
                  final address = addressController.addresses[index];
                  return Obx(
                    () => Card(
                      elevation: selectedAddressId.value == address.id ? 4 : 1,
                      color:
                          selectedAddressId.value == address.id
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                      child: RadioListTile<String>(
                        value: address.id,
                        groupValue: selectedAddressId.value,
                        onChanged: (value) => selectedAddressId.value = value!,
                        title: Text(
                          '${address.name} - ${address.phone}',
                          style: TextStyle(
                            fontWeight:
                                selectedAddressId.value == address.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${address.addressLine1}, '
                          '${address.addressLine2 != null ? "${address.addressLine2}, " : ""}'
                          '${address.city}, ${address.state} ${address.zip}, '
                          '${address.country}',
                        ),
                        secondary:
                            address.isDefault
                                ? const Chip(label: Text('Default'))
                                : null,
                        selected: selectedAddressId.value == address.id,
                      ),
                    ),
                  );
                },
              );
            }),
            const Spacer(),
            // Order Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('₹${cartController.total.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('Shipping'), Text('₹0.00')],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${cartController.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed:
                      selectedAddressId.value.isEmpty
                          ? null
                          : proceedToPayment,
                  child: const Text('Proceed to Payment'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
