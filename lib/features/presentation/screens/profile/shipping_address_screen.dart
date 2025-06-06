import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../features/presentation/screens/profile/add_address_screen.dart';
import '../../../../features/presentation/controllers/address_controller.dart';

class ShippingAddressScreen extends StatelessWidget {
  final addressController = Get.put(AddressController());

  ShippingAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const AddAddressScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (addressController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (addressController.addresses.isEmpty) {
          return const Center(child: Text('No addresses added yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addressController.addresses.length,
          itemBuilder: (context, index) {
            final address = addressController.addresses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Spacer(),
                        PopupMenuButton(
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                                if (!address.isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Set as Default'),
                                  ),
                              ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                Get.to(
                                  () => AddAddressScreen(
                                    isEditing: true,
                                    address: {
                                      'id': address.id,
                                      'name': address.name,
                                      'phone': address.phone,
                                      'address_line1': address.addressLine1,
                                      'address_line2': address.addressLine2,
                                      'city': address.city,
                                      'state': address.state,
                                      'zip': address.zip,
                                      'is_default': address.isDefault,
                                    },
                                  ),
                                );
                                break;
                              case 'delete':
                                Get.dialog(
                                  AlertDialog(
                                    title: const Text('Delete Address'),
                                    content: const Text(
                                      'Are you sure you want to delete this address?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Get.back();
                                          addressController.deleteAddress(
                                            address.id,
                                          );
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                break;
                              case 'default':
                                addressController.setDefaultAddress(address.id);
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(address.phone),
                    const SizedBox(height: 4),
                    Text(address.addressLine1),
                    if (address.addressLine2 != null) ...[
                      const SizedBox(height: 4),
                      Text(address.addressLine2!),
                    ],
                    const SizedBox(height: 4),
                    Text('${address.city}, ${address.state} ${address.zip}'),
                    const SizedBox(height: 4),
                    Text(address.country),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddAddressScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
