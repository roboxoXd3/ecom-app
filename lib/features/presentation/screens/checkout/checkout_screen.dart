import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/cart_controller.dart';
import '../../../../core/utils/snackbar_utils.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final RxInt currentStep = 0.obs;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Form controllers
    final fullNameController = TextEditingController();
    final address1Controller = TextEditingController();
    final address2Controller = TextEditingController();
    final cityController = TextEditingController();
    final postalCodeController = TextEditingController();
    final phoneController = TextEditingController();
    final RxString selectedPaymentMethod = 'card'.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Obx(
        () => Stepper(
          currentStep: currentStep.value,
          onStepContinue: () {
            if (currentStep.value == 0) {
              if (formKey.currentState!.validate()) {
                currentStep.value++;
              }
            } else if (currentStep.value < 2) {
              currentStep.value++;
            } else {
              // Place order
              Get.defaultDialog(
                title: 'Order Placed',
                middleText: 'Your order has been placed successfully!',
                textConfirm: 'OK',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  cartController.clearCart();
                  Get.until((route) => route.isFirst);
                  SnackbarUtils.showSuccess('Order placed successfully');
                },
              );
            }
          },
          onStepCancel: () {
            if (currentStep.value > 0) {
              currentStep.value--;
            }
          },
          steps: [
            Step(
              title: const Text('Shipping Address'),
              content: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: address1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: address2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2 (Optional)',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              prefixIcon: Icon(
                                Icons.local_post_office_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter postal code';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!GetUtils.isPhoneNumber(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              isActive: currentStep.value >= 0,
            ),
            Step(
              title: const Text('Payment Method'),
              content: Column(
                children: [
                  Obx(
                    () => RadioListTile(
                      value: 'card',
                      groupValue: selectedPaymentMethod.value,
                      onChanged:
                          (value) => selectedPaymentMethod.value = value!,
                      title: const Text('Credit/Debit Card'),
                      subtitle: const Text('Pay with Visa, Mastercard, etc.'),
                      secondary: const Icon(Icons.credit_card),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => RadioListTile(
                      value: 'paypal',
                      groupValue: selectedPaymentMethod.value,
                      onChanged:
                          (value) => selectedPaymentMethod.value = value!,
                      title: const Text('PayPal'),
                      subtitle: const Text('Pay with your PayPal account'),
                      secondary: const Icon(Icons.payment),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => RadioListTile(
                      value: 'cod',
                      groupValue: selectedPaymentMethod.value,
                      onChanged:
                          (value) => selectedPaymentMethod.value = value!,
                      title: const Text('Cash on Delivery'),
                      subtitle: const Text('Pay when you receive'),
                      secondary: const Icon(Icons.money),
                    ),
                  ),
                ],
              ),
              isActive: currentStep.value >= 1,
            ),
            Step(
              title: const Text('Order Summary'),
              content: Column(
                children: [
                  ...cartController.items.map(
                    (item) => ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        'Size: ${item.selectedSize} • Color: ${item.selectedColor}',
                      ),
                      trailing: Text(
                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      'Subtotal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '\$${cartController.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Shipping',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '\$${(cartController.total * 0.1).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Text(
                      '\$${(cartController.total * 1.1).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              isActive: currentStep.value >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
