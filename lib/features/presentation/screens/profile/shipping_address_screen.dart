import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/presentation/screens/profile/add_address_screen.dart';

class ShippingAddressScreen extends StatelessWidget {
  const ShippingAddressScreen({super.key});

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, // Dummy data count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (index == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
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
                              if (index != 0)
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
                                    'name': 'John Doe',
                                    'phone': '+1 234 567 890',
                                    'addressLine1': '123 Main Street',
                                    'addressLine2': 'Apt 4B',
                                    'city': 'New York',
                                    'state': 'NY',
                                    'zip': '10001',
                                    'country': 'United States',
                                    'isDefault': index == 0,
                                  },
                                ),
                              );
                              break;
                            case 'delete':
                              // Show confirmation dialog
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
                                        // TODO: Implement delete logic
                                        Get.back();
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
                              // TODO: Implement set as default logic
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('John Doe'),
                  const SizedBox(height: 4),
                  const Text('123 Main Street'),
                  const SizedBox(height: 4),
                  const Text('Apt 4B'),
                  const SizedBox(height: 4),
                  const Text('New York, NY 10001'),
                  const SizedBox(height: 4),
                  const Text('United States'),
                  const SizedBox(height: 4),
                  const Text('+1 234 567 890'),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddAddressScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
