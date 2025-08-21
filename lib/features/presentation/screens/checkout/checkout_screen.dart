import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../controllers/address_controller.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final addressController = Get.find<AddressController>();
    final selectedAddressId = ''.obs;

    // Auto-select default address when addresses are loaded
    ever(addressController.addresses, (addresses) {
      if (addresses.isNotEmpty && selectedAddressId.value.isEmpty) {
        // Find default address or select first one
        final defaultAddress = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );
        selectedAddressId.value = defaultAddress.id;
      }
    });

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
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
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
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No addresses found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Get.toNamed('/add-address'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Address'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Address selection with constrained height
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: addressController.addresses.length,
                            itemBuilder: (context, index) {
                              final address =
                                  addressController.addresses[index];
                              return Obx(
                                () => Card(
                                  elevation:
                                      selectedAddressId.value == address.id
                                          ? 4
                                          : 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color:
                                      selectedAddressId.value == address.id
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                          : null,
                                  child: RadioListTile<String>(
                                    value: address.id,
                                    groupValue: selectedAddressId.value,
                                    onChanged:
                                        (value) =>
                                            selectedAddressId.value = value!,
                                    title: Text(
                                      '${address.name} - ${address.phone}',
                                      style: TextStyle(
                                        fontWeight:
                                            selectedAddressId.value ==
                                                    address.id
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${address.addressLine1}, '
                                      '${address.addressLine2 != null ? "${address.addressLine2}, " : ""}'
                                      '${address.city}, ${address.state} ${address.zip}, '
                                      '${address.country}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    secondary:
                                        address.isDefault
                                            ? const Chip(
                                              label: Text('Default'),
                                              labelStyle: TextStyle(
                                                fontSize: 12,
                                              ),
                                            )
                                            : null,
                                    selected:
                                        selectedAddressId.value == address.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add new address button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Get.toNamed('/add-address'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Address'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Order Summary Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subtotal',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '₹${cartController.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Shipping',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Free',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${cartController.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          // Fixed bottom section with payment button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        selectedAddressId.value.isEmpty
                            ? null
                            : proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selectedAddressId.value.isEmpty
                          ? 'Select Address to Continue'
                          : 'Proceed to Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
