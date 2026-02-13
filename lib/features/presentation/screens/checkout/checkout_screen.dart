import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/address_controller.dart';
import '../../controllers/currency_controller.dart';
import '../profile/add_address_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late CheckoutController checkoutController;
  late AddressController addressController;
  Worker? _addressWorker;
  final ScrollController _addressScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    checkoutController = Get.put(CheckoutController());
    Get.put(OrderController()); // Ensure OrderController is available
    addressController = Get.find<AddressController>();

    // Refresh address selection when screen is focused (returning from add address)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkoutController.refreshAddressSelection();
      // Scroll to selected address on initial load
      final selectedId = checkoutController.selectedAddressId.value;
      if (selectedId.isNotEmpty) {
        _scrollToSelectedAddress(selectedId);
      }
    });

    // Auto-select address when addresses are loaded or updated
    // Store the worker reference so we can dispose it later
    _addressWorker = ever(addressController.addresses, (addresses) {
      print('CheckoutScreen: Address list updated, count: ${addresses.length}');
      if (addresses.isNotEmpty) {
        final currentSelectedId = checkoutController.selectedAddressId.value;
        print('CheckoutScreen: Current selected ID: "$currentSelectedId"');

        // Check if currently selected address still exists
        final currentSelectedExists =
            currentSelectedId.isNotEmpty &&
            addresses.any((addr) => addr.id == currentSelectedId);

        print('CheckoutScreen: Current address exists: $currentSelectedExists');

        // Auto-select logic:
        // 1. If no address is selected, select default or first
        // 2. If current address doesn't exist anymore, select default or first
        // 3. If a new default address was added, switch to it
        if (currentSelectedId.isEmpty || !currentSelectedExists) {
          final defaultAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );
          print(
            'CheckoutScreen: Auto-selecting address: "${defaultAddress.id}" (isDefault: ${defaultAddress.isDefault})',
          );
          checkoutController.setSelectedAddress(defaultAddress.id);
          _scrollToSelectedAddress(defaultAddress.id);
        } else {
          // Check if there's a new default address that should take priority
          final defaultAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );

          // If the default address is different from currently selected,
          // and it's actually marked as default, switch to it
          if (defaultAddress.isDefault &&
              defaultAddress.id != currentSelectedId) {
            print(
              'CheckoutScreen: Switching to new default address: "${defaultAddress.id}"',
            );
            checkoutController.setSelectedAddress(defaultAddress.id);
            _scrollToSelectedAddress(defaultAddress.id);
          } else {
            print(
              'CheckoutScreen: Keeping current selection: "$currentSelectedId"',
            );
          }
        }
      } else {
        print('CheckoutScreen: No addresses available');
        checkoutController.selectedAddressId.value = '';
      }
    });
  }

  @override
  void dispose() {
    // Clean up the worker to prevent memory leaks
    _addressWorker?.dispose();
    _addressScrollController.dispose();
    super.dispose();
  }

  // Method to scroll to the selected address
  void _scrollToSelectedAddress(String selectedId) {
    if (selectedId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addresses = addressController.addresses;
      final selectedIndex = addresses.indexWhere(
        (addr) => addr.id == selectedId,
      );

      if (selectedIndex != -1 && _addressScrollController.hasClients) {
        // Calculate the position (each item is approximately 120 pixels high)
        final position = selectedIndex * 120.0;
        final maxScroll = _addressScrollController.position.maxScrollExtent;
        final targetPosition = position > maxScroll ? maxScroll : position;

        _addressScrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Method to handle adding a new address
  Future<void> _handleAddNewAddress() async {
    print('CheckoutScreen: Opening add address screen...');
    
    final result = await Get.to(() => const AddAddressScreen());
    
    print('CheckoutScreen: Returned from add address with result: $result');
    
    // Always refresh addresses when returning, regardless of result
    await addressController.fetchAddresses();
    
    // Handle different return types
    if (result is String) {
      // New address ID returned - select it directly
      print('CheckoutScreen: New address created with ID: $result, selecting it...');
      await Future.delayed(const Duration(milliseconds: 100));
      checkoutController.setSelectedAddress(result);
      _scrollToSelectedAddress(result);
      checkoutController.update();
    } else if (result == true) {
      // Old boolean success - use existing logic
      print('CheckoutScreen: Address added successfully (legacy), refreshing state...');
      await Future.delayed(const Duration(milliseconds: 100));
      checkoutController.refreshAddressSelection();
      checkoutController.update();
    } else {
      print('CheckoutScreen: Address addition was not successful or cancelled');
      // Still refresh the selection in case there were changes
      checkoutController.refreshAddressSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final currencyController = Get.find<CurrencyController>();

    void showPaymentMethodDialog() {
      Get.bottomSheet(
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getTextSecondary(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.getTextSecondary(context),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.getBorder(
                          context,
                        ).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Payment methods list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: checkoutController.paymentMethods.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final method = checkoutController.paymentMethods[index];
                    return Obx(() {
                      final isSelected =
                          checkoutController.selectedPaymentMethod.value ==
                          method['id'];

                      return InkWell(
                        onTap: () {
                          checkoutController.setSelectedPaymentMethod(
                            method['id'],
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.08)
                                    : AppTheme.getSurface(context),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.getBorder(
                                        context,
                                      ).withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Payment method icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor.withOpacity(
                                            0.15,
                                          )
                                          : AppTheme.getBorder(
                                            context,
                                          ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method['icon'],
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.getTextSecondary(context),
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Payment method details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.getTextSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.getBorder(context),
                                    width: 2,
                                  ),
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.getBorder(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              checkoutController.isProcessingOrder.value ||
                                      checkoutController
                                          .isInitiatingPayment
                                          .value ||
                                      checkoutController
                                          .isShowingPaymentLoader
                                          .value
                                  ? null
                                  : () {
                                    Get.back();
                                    checkoutController.initiatePayment();
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              checkoutController.isProcessingOrder.value ||
                                      checkoutController
                                          .isInitiatingPayment
                                          .value ||
                                      checkoutController
                                          .isShowingPaymentLoader
                                          .value
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Proceed to Payment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                Icons.add_location_alt,
                color: addressController.isLoading.value
                    ? AppTheme.getTextSecondary(context).withOpacity(0.5)
                    : AppTheme.getTextPrimary(context),
              ),
              tooltip: 'Add New Address',
              onPressed: addressController.isLoading.value
                  ? null
                  : _handleAddNewAddress,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (addressController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (addressController.addresses.isEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No addresses found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _handleAddNewAddress,
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
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: ListView.builder(
                                controller: _addressScrollController,
                                shrinkWrap: true,
                                itemCount: addressController.addresses.length,
                                itemBuilder: (context, index) {
                                  final address =
                                      addressController.addresses[index];
                                  return Obx(() {
                                    final isSelected =
                                        checkoutController
                                            .selectedAddressId
                                            .value ==
                                        address.id;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.getBorder(context),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                    .withOpacity(0.08)
                                                : AppTheme.getSurface(context),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap:
                                              () => checkoutController
                                                  .setSelectedAddress(
                                                    address.id,
                                                  ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                // Radio button
                                                Radio<String>(
                                                  value: address.id,
                                                  groupValue:
                                                      checkoutController
                                                          .selectedAddressId
                                                          .value,
                                                  onChanged:
                                                      (
                                                        value,
                                                      ) => checkoutController
                                                          .setSelectedAddress(
                                                            value!,
                                                          ),
                                                  activeColor:
                                                      AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 12),
                                                // Address content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Name and phone row
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '${address.name} - ${address.phone}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    isSelected
                                                                        ? FontWeight
                                                                            .w600
                                                                        : FontWeight
                                                                            .w500,
                                                                fontSize: 16,
                                                                color:
                                                                    AppTheme.getTextPrimary(
                                                                      context,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (address.isDefault)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    AppTheme
                                                                        .primaryColor,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child: const Text(
                                                                'Default',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Address text
                                                      Text(
                                                        '${address.addressLine1}${address.addressLine2 != null ? ", ${address.addressLine2}" : ""}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              AppTheme.getTextSecondary(
                                                                context,
                                                              ),
                                                          height: 1.4,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${address.city}, ${address.state} ${address.zip}, ${address.country}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              AppTheme.getTextSecondary(
                                                                context,
                                                              ),
                                                          height: 1.4,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Loyalty Voucher Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.getSurface(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.getBorder(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Loyalty Voucher',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.getTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(() {
                                    if (checkoutController
                                        .voucherApplied
                                        .value) {
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Voucher Applied: ${checkoutController.voucherCode.value}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Discount: ${CurrencyUtils.formatAmount(checkoutController.voucherDiscount.value)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () =>
                                                      checkoutController
                                                          .clearVoucher(),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: InputDecoration(
                                                hintText: 'Enter voucher code',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              textCapitalization:
                                                  TextCapitalization.characters,
                                              onChanged:
                                                  (value) =>
                                                      checkoutController
                                                          .voucherCode
                                                          .value = value,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Obx(() {
                                              return ElevatedButton(
                                                onPressed:
                                                    checkoutController
                                                            .isValidatingVoucher
                                                            .value
                                                        ? null
                                                        : () => checkoutController
                                                            .applyVoucher(
                                                              checkoutController
                                                                  .voucherCode
                                                                  .value,
                                                            ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12,
                                                      ),
                                                ),
                                                child:
                                                    checkoutController
                                                            .isValidatingVoucher
                                                            .value
                                                        ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                                  Colors.white,
                                                                ),
                                                          ),
                                                        )
                                                        : const Text('Apply'),
                                              );
                                            }),
                                          ),
                                        ],
                                      );
                                    }
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Order Items Section
                            Obx(() {
                              // Handle empty cart case
                              if (cartController.items.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.getBorder(context),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_bag,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Order Items (${cartController.items.length})',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.getTextPrimary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...cartController.items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final isLast = index == cartController.items.length - 1;
                                      
                                      return Column(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                // Navigate to product details page
                                                Get.toNamed('/product-details', arguments: item.product.id);
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Product Image
                                                    Container(
                                                      width: 70,
                                                      height: 70,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: AppTheme.getSurface(context),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: item.product.imageList.isNotEmpty
                                                            ? CachedNetworkImage(
                                                                imageUrl: item.product.imageList.first,
                                                                fit: BoxFit.cover,
                                                                placeholder: (context, url) => Container(
                                                                  color: AppTheme.getSurface(context),
                                                                  child: const Center(
                                                                    child: SizedBox(
                                                                      width: 20,
                                                                      height: 20,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth: 2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                errorWidget: (context, url, error) => Container(
                                                                  color: AppTheme.getSurface(context),
                                                                  child: Icon(
                                                                    Icons.image,
                                                                    color: AppTheme.getTextSecondary(context),
                                                                    size: 24,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                color: AppTheme.getSurface(context),
                                                                child: Icon(
                                                                  Icons.image,
                                                                  color: AppTheme.getTextSecondary(context),
                                                                  size: 24,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Product Details
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item.product.name,
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w600,
                                                              color: AppTheme.getTextPrimary(context),
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Qty: ${item.quantity} • Size: ${item.selectedSize} • Color: ${item.selectedColor}',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme.getTextSecondary(context),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Obx(() {
                                                            final itemTotal = currencyController.convertPrice(
                                                                  item.product.price,
                                                                  item.product.currency,
                                                                ) *
                                                                item.quantity;
                                                            return Text(
                                                              currencyController.formatPrice(itemTotal),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppTheme.primaryColor,
                                                              ),
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    ),
                                                    // Arrow indicator
                                                    Icon(
                                                      Icons.chevron_right,
                                                      color: AppTheme.getTextSecondary(context),
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 24,
                                              color: AppTheme.getBorder(context).withOpacity(0.5),
                                            ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            // Order Summary Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.getSurface(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.getBorder(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getTextPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.getTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Obx(
                                          () => Text(
                                            CurrencyUtils.formatAmount(
                                              cartController.total,
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppTheme.getTextPrimary(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Shipping',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.getTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Free',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Obx(() {
                                    if (checkoutController
                                        .voucherApplied
                                        .value) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Discount',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              Text(
                                                '- ${CurrencyUtils.formatAmount(checkoutController.voucherDiscount.value)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.getTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Obx(
                                          () => Text(
                                            CurrencyUtils.formatAmount(
                                              checkoutController.total,
                                            ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
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
                    child: Obx(() {
                      // Explicitly watch both reactive values
                      final selectedAddressId =
                          checkoutController.selectedAddressId.value;
                      final cartItems = cartController.items.length;
                      final canProceed =
                          selectedAddressId.isNotEmpty && cartItems > 0;

                      print(
                        'CheckoutScreen: Button Obx rebuild - addressId: "$selectedAddressId", cartItems: $cartItems, canProceed: $canProceed',
                      );

                      return ElevatedButton(
                        onPressed: !canProceed ? null : showPaymentMethodDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          !canProceed
                              ? 'Select Address to Continue'
                              : 'Proceed to Payment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),

          // Full-screen loading overlay
          Obx(() {
            if (!checkoutController.isShowingPaymentLoader.value) {
              return const SizedBox.shrink();
            }

            return Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Connecting to Payment Gateway',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextPrimary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please wait while we securely process\nyour payment request...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getTextSecondary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.security,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secure Payment by Squad',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
