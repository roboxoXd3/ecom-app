import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/order_controller.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../controllers/address_controller.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final addressController = Get.find<AddressController>();

    // Initialize controllers
    final checkoutController = Get.put(CheckoutController());
    Get.put(OrderController()); // Ensure OrderController is available

    // Auto-select default address when addresses are loaded
    ever(addressController.addresses, (addresses) {
      if (addresses.isNotEmpty &&
          checkoutController.selectedAddressId.value.isEmpty) {
        // Find default address or select first one
        final defaultAddress = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );
        checkoutController.setSelectedAddress(defaultAddress.id);
      }
    });

    void proceedToPayment() async {
      if (!checkoutController.canProceedToPayment) {
        SnackbarUtils.showError('Please select an address');
        return;
      }

      // Show payment processing dialog
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent dismissing during processing
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  checkoutController.getPaymentMethodIcon(
                    checkoutController.selectedPaymentMethod.value,
                  ),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Processing Payment'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () =>
                      checkoutController.isProcessingOrder.value
                          ? Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                checkoutController
                                            .selectedPaymentMethod
                                            .value ==
                                        'cash_on_delivery'
                                    ? 'Creating your order...'
                                    : 'Processing payment...',
                              ),
                            ],
                          )
                          : Column(
                            children: [
                              Text(
                                'Payment Method: ${checkoutController.getPaymentMethodName(checkoutController.selectedPaymentMethod.value)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: ₹${checkoutController.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (checkoutController
                                      .selectedPaymentMethod
                                      .value ==
                                  'cash_on_delivery')
                                const Text(
                                  'Your order will be confirmed and you can pay when it\'s delivered.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                const Text(
                                  'This is a payment simulation. In a real app, this would integrate with your payment gateway.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                ),
              ],
            ),
            actions: [
              if (!checkoutController.isProcessingOrder.value) ...[
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    checkoutController.simulatePayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    checkoutController.selectedPaymentMethod.value ==
                            'cash_on_delivery'
                        ? 'Confirm Order'
                        : 'Pay Now',
                  ),
                ),
              ],
            ],
          ),
        ),
        barrierDismissible: false,
      );
    }

    void showPaymentMethodDialog() {
      Get.dialog(
        AlertDialog(
          title: const Text(
            'Select Payment Method',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  checkoutController.paymentMethods.map((method) {
                    return Obx(
                      () => RadioListTile<String>(
                        value: method['id'],
                        groupValue:
                            checkoutController.selectedPaymentMethod.value,
                        onChanged: (value) {
                          checkoutController.setSelectedPaymentMethod(value!);
                        },
                        title: Row(
                          children: [
                            Icon(method['icon'], size: 20),
                            const SizedBox(width: 8),
                            Text(method['name']),
                          ],
                        ),
                        subtitle: Text(
                          method['description'],
                          style: const TextStyle(fontSize: 12),
                        ),
                        activeColor: AppTheme.primaryColor,
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            Obx(
              () => ElevatedButton(
                onPressed:
                    checkoutController.isProcessingOrder.value
                        ? null
                        : () {
                          Get.back();
                          proceedToPayment();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child:
                    checkoutController.isProcessingOrder.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Proceed to Payment'),
              ),
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
                                      checkoutController
                                                  .selectedAddressId
                                                  .value ==
                                              address.id
                                          ? 4
                                          : 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color:
                                      checkoutController
                                                  .selectedAddressId
                                                  .value ==
                                              address.id
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                          : null,
                                  child: Obx(
                                    () => RadioListTile<String>(
                                      value: address.id,
                                      groupValue:
                                          checkoutController
                                              .selectedAddressId
                                              .value,
                                      onChanged:
                                          (value) => checkoutController
                                              .setSelectedAddress(value!),
                                      title: Text(
                                        '${address.name} - ${address.phone}',
                                        style: TextStyle(
                                          fontWeight:
                                              checkoutController
                                                          .selectedAddressId
                                                          .value ==
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
                                          checkoutController
                                              .selectedAddressId
                                              .value ==
                                          address.id,
                                    ),
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
                        !checkoutController.canProceedToPayment
                            ? null
                            : showPaymentMethodDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      !checkoutController.canProceedToPayment
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
