import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/order_model.dart';
import '../../data/services/squad_payment_service.dart';
import '../screens/payment/squad_payment_webview.dart';
import 'loyalty_controller.dart';
import 'order_controller.dart';
import 'cart_controller.dart';
import 'auth_controller.dart';
import 'currency_controller.dart';
import 'address_controller.dart';
import '../../../core/utils/snackbar_utils.dart';

class CheckoutController extends GetxController {
  final OrderController _orderController = Get.find<OrderController>();
  final CartController _cartController = Get.find<CartController>();
  final CurrencyController _currencyController = Get.find<CurrencyController>();

  final RxBool isProcessingOrder = false.obs;
  final RxBool isInitiatingPayment = false.obs;
  final RxBool isShowingPaymentLoader = false.obs;
  final RxString selectedAddressId = ''.obs;
  final RxString selectedPaymentMethod = 'cash_on_delivery'.obs;
  final RxString currentTransactionRef = ''.obs;

  // Loyalty voucher fields
  final RxString voucherCode = ''.obs;
  final RxBool isValidatingVoucher = false.obs;
  final RxBool voucherApplied = false.obs;
  final RxDouble voucherDiscount = 0.0.obs;
  final RxString voucherType = ''.obs; // 'percentage' or 'fixed'
  final RxDouble voucherValue = 0.0.obs;

  // Payment method options
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'cash_on_delivery',
      'name': 'Cash on Delivery',
      'icon': Icons.money,
      'description': 'Pay when your order is delivered',
    },
    {
      'id': 'credit_card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Secure online payment',
    },
    {
      'id': 'upi',
      'name': 'UPI Payment',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay using UPI apps',
    },
    {
      'id': 'net_banking',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'description': 'Pay using your bank account',
    },
  ];

  void setSelectedAddress(String addressId) {
    selectedAddressId.value = addressId;
    debugCheckoutState(); // Debug the state after setting address
    // Force UI update
    update();
  }

  void setSelectedPaymentMethod(String paymentMethodId) {
    selectedPaymentMethod.value = paymentMethodId;
  }

  // Method to refresh address selection - useful when returning from add address screen
  void refreshAddressSelection() {
    print('CheckoutController: Refreshing address selection...');
    if (Get.isRegistered<AddressController>()) {
      final addressController = Get.find<AddressController>();
      final addresses = addressController.addresses;

      print('CheckoutController: Found ${addresses.length} addresses');

      if (addresses.isNotEmpty) {
        final currentSelectedId = selectedAddressId.value;
        print('CheckoutController: Current selected ID: "$currentSelectedId"');

        // Check if current address still exists
        final currentExists =
            currentSelectedId.isNotEmpty &&
            addresses.any((addr) => addr.id == currentSelectedId);

        print('CheckoutController: Current address exists: $currentExists');

        // Always prioritize default address if it exists
        final defaultAddress = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );

        print(
          'CheckoutController: Default address ID: "${defaultAddress.id}", isDefault: ${defaultAddress.isDefault}',
        );

        // Select default address if:
        // 1. No address is currently selected
        // 2. Current address doesn't exist anymore
        // 3. There's a default address and it's different from current
        if (currentSelectedId.isEmpty ||
            !currentExists ||
            (defaultAddress.isDefault &&
                defaultAddress.id != currentSelectedId)) {
          print(
            'CheckoutController: Setting new selected address: "${defaultAddress.id}"',
          );
          setSelectedAddress(defaultAddress.id);
        } else {
          print('CheckoutController: Keeping current address selection');
          debugCheckoutState();
        }
      } else {
        print('CheckoutController: No addresses available');
        selectedAddressId.value = '';
      }
    } else {
      print('CheckoutController: AddressController not registered');
    }
  }

  double get subtotal => _cartController.total;
  double get shippingFee => 0.0; // Free shipping for now
  double get total => subtotal + shippingFee - voucherDiscount.value;

  bool get canProceedToPayment {
    final canProceed =
        selectedAddressId.value.isNotEmpty && _cartController.items.isNotEmpty;
    print(
      'CheckoutController: canProceedToPayment getter called - result: $canProceed',
    );
    return canProceed;
  }

  // Validate and apply voucher
  Future<void> applyVoucher(String code) async {
    if (code.trim().isEmpty) {
      SnackbarUtils.showError('Please enter a voucher code');
      return;
    }

    try {
      isValidatingVoucher.value = true;

      // Get user ID
      final authController = Get.find<AuthController>();
      final user = authController.supabase.auth.currentUser;
      if (user == null) {
        SnackbarUtils.showError('Please login to apply voucher');
        return;
      }

      // Call REST API to validate voucher
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final response = await http.post(
        Uri.parse('$apiUrl/api/loyalty/validate-voucher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'voucherCode': code.toUpperCase(),
          'orderAmount': subtotal,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['valid'] == true) {
        voucherCode.value = code.toUpperCase();
        voucherApplied.value = true;
        voucherType.value = data['discount_type'];
        voucherValue.value =
            (data['discount_value'] is int)
                ? (data['discount_value'] as int).toDouble()
                : data['discount_value'].toDouble();

        // Calculate discount - use server-calculated amount
        if (data['discount_type'] == 'discount_percentage') {
          voucherDiscount.value =
              (data['discount_amount'] is int)
                  ? (data['discount_amount'] as int).toDouble()
                  : data['discount_amount'].toDouble();
        } else {
          voucherDiscount.value =
              (data['discount_value'] is int)
                  ? (data['discount_value'] as int).toDouble()
                  : data['discount_value'].toDouble();
        }

        SnackbarUtils.showSuccess('Voucher applied successfully!');
      } else {
        throw Exception(data['error'] ?? 'Invalid voucher');
      }
    } catch (e) {
      print('Voucher validation error: $e');
      SnackbarUtils.showError(
        e.toString().contains('Exception: ')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Invalid or expired voucher code',
      );
      clearVoucher();
    } finally {
      isValidatingVoucher.value = false;
    }
  }

  void clearVoucher() {
    voucherCode.value = '';
    voucherApplied.value = false;
    voucherDiscount.value = 0.0;
    voucherType.value = '';
    voucherValue.value = 0.0;
  }

  // Debug method to check checkout state
  void debugCheckoutState() {
    print('=== CHECKOUT DEBUG ===');
    print('selectedAddressId: "${selectedAddressId.value}"');
    print('cart items count: ${_cartController.items.length}');
    print('canProceedToPayment: $canProceedToPayment');
    print('isProcessingOrder: ${isProcessingOrder.value}');
    print('======================');
  }

  Future<bool> processOrder() async {
    print('CheckoutController: Starting processOrder');
    print('CheckoutController: canProceedToPayment = $canProceedToPayment');
    print('CheckoutController: selectedAddressId = ${selectedAddressId.value}');
    print(
      'CheckoutController: cart items count = ${_cartController.items.length}',
    );

    if (!canProceedToPayment) {
      print('CheckoutController: Cannot proceed to payment');
      SnackbarUtils.showError(
        'Please select an address and ensure cart is not empty',
      );
      return false;
    }

    try {
      isProcessingOrder.value = true;
      print('CheckoutController: Processing order...');

      // Convert cart items to order items
      final orderItems =
          _cartController.items
              .map(
                (cartItem) => OrderItem(
                  id: '', // Will be generated by database
                  orderId: '', // Will be set by repository
                  productId: cartItem.product.id,
                  quantity: cartItem.quantity,
                  price: cartItem.product.price,
                  selectedSize: cartItem.selectedSize,
                  selectedColor: cartItem.selectedColor,
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      print('CheckoutController: Created ${orderItems.length} order items');
      print('CheckoutController: Order total = $total');

      // Create the order
      final success = await _orderController.createOrder(
        addressId: selectedAddressId.value,
        paymentMethodId: selectedPaymentMethod.value,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: orderItems,
        loyaltyVoucherCode: voucherApplied.value ? voucherCode.value : null,
      );

      print('CheckoutController: Order creation success = $success');

      if (success) {
        print('CheckoutController: Clearing cart...');
        // Clear the cart after successful order creation
        await _cartController.clearCart();
        print('CheckoutController: Cart cleared successfully');

        // Refresh vouchers if one was used
        if (voucherApplied.value) {
          try {
            final loyaltyController = Get.find<LoyaltyController>();
            await loyaltyController.loadVouchers();
            print('CheckoutController: Vouchers refreshed after order');
          } catch (e) {
            print('CheckoutController: Error refreshing vouchers: $e');
            // Don't fail order if voucher refresh fails
          }
        }

        return true;
      } else {
        print('CheckoutController: Order creation failed');
        return false;
      }
    } catch (e) {
      print('CheckoutController: Error processing order: $e');
      SnackbarUtils.showError('Failed to process order. Please try again.');
      return false;
    } finally {
      isProcessingOrder.value = false;
      print('CheckoutController: processOrder completed');
    }
  }

  // Debug method to check auth status
  void debugAuthStatus() {
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      print('=== AUTH DEBUG ===');
      print('AuthController registered: ${Get.isRegistered<AuthController>()}');
      print('userEmail.value: "${authController.userEmail.value}"');
      print('currentUser.value: ${authController.currentUser.value}');
      print('currentUser email: ${authController.currentUser.value?.email}');
      print(
        'Supabase currentUser: ${authController.supabase.auth.currentUser}',
      );
      print(
        'Supabase user email: ${authController.supabase.auth.currentUser?.email}',
      );
      print('==================');
    } else {
      print('AuthController NOT registered!');
    }
  }

  Future<void> initiatePayment() async {
    // Debug auth status first
    debugAuthStatus();

    if (!canProceedToPayment) {
      SnackbarUtils.showError(
        'Please select an address and ensure cart is not empty',
      );
      return;
    }

    try {
      // Show loading overlay BEFORE closing modal
      isShowingPaymentLoader.value = true;

      // Small delay to ensure modal animates closed first
      await Future.delayed(const Duration(milliseconds: 100));

      isInitiatingPayment.value = true;

      // Handle Cash on Delivery
      if (selectedPaymentMethod.value == 'cash_on_delivery') {
        await _processCODOrder();
        return;
      }

      // Handle online payments through Squad
      await _initiateSquadPayment();
    } catch (e) {
      print('Error initiating payment: $e');
      SnackbarUtils.showError('Failed to initiate payment. Please try again.');
    } finally {
      isInitiatingPayment.value = false;
      isShowingPaymentLoader.value = false; // Hide overlay
    }
  }

  Future<void> _processCODOrder() async {
    try {
      isProcessingOrder.value = true;

      // Create order with COD payment method
      final success = await processOrder();

      if (success) {
        SnackbarUtils.showSuccess('Order placed successfully!');
        Get.offNamed('/order-confirmation');
      }
    } finally {
      isProcessingOrder.value = false;
    }
  }

  Future<void> _initiateSquadPayment() async {
    try {
      // Validate network connectivity first
      if (!await _checkNetworkConnectivity()) {
        SnackbarUtils.showError(
          'No internet connection. Please check your network and try again.',
        );
        return;
      }

      // Get user email for payment
      if (!Get.isRegistered<AuthController>()) {
        SnackbarUtils.showError(
          'Authentication system not ready. Please restart the app.',
        );
        return;
      }

      final authController = Get.find<AuthController>();

      // Try multiple ways to get user email
      String? userEmail = authController.userEmail.value;
      if (userEmail.isEmpty) {
        userEmail = authController.currentUser.value?.email;
      }
      if (userEmail == null || userEmail.isEmpty) {
        // Fallback to Supabase auth directly
        userEmail = authController.supabase.auth.currentUser?.email;
      }

      if (userEmail == null || userEmail.isEmpty) {
        SnackbarUtils.showError('User email not found. Please login again.');
        print(
          'Debug: AuthController userEmail: ${authController.userEmail.value}',
        );
        print(
          'Debug: CurrentUser email: ${authController.currentUser.value?.email}',
        );
        print(
          'Debug: Supabase user: ${authController.supabase.auth.currentUser?.email}',
        );
        return;
      }

      // Generate transaction reference
      currentTransactionRef.value =
          SquadPaymentService.generateTransactionRef();

      // Prepare payment data
      final paymentChannels = _getPaymentChannels();
      final callbackUrl =
          'https://ecomadmin-production.up.railway.app/api/payments/webhook';
      final redirectUrl =
          'https://ecomadmin-production.up.railway.app/api/payments/success';

      print('Initiating Squad payment...');
      print('Amount: $total');
      print('Email: $userEmail');
      print('Transaction Ref: ${currentTransactionRef.value}');

      // Initiate payment with Squad
      final paymentResponse = await SquadPaymentService.initiatePayment(
        amount: total,
        email: userEmail,
        transactionRef: currentTransactionRef.value,
        currency:
            _currencyController.selectedCurrency.value, // Use selected currency
        callbackUrl: callbackUrl,
        redirectUrl: redirectUrl,
        paymentChannels: paymentChannels,
        metadata: {
          'order_type': 'ecommerce',
          'customer_id':
              authController.currentUser.value?.id ??
              authController.supabase.auth.currentUser?.id,
          'cart_items': _cartController.items.length,
          'selected_address': selectedAddressId.value,
        },
      );

      if (paymentResponse.success && paymentResponse.checkoutUrl != null) {
        // Hide loader before navigating
        isShowingPaymentLoader.value = false;

        // Navigate to payment WebView
        Get.to(
          () => SquadPaymentWebView(
            checkoutUrl: paymentResponse.checkoutUrl!,
            transactionRef: currentTransactionRef.value,
            onPaymentComplete: _handlePaymentResult,
          ),
        );
      } else {
        throw Exception(paymentResponse.message);
      }
    } catch (e) {
      print('Squad payment initiation error: $e');

      // Hide loader on error
      isShowingPaymentLoader.value = false;

      // Provide specific error handling and fallback options
      if (e is SquadPaymentException) {
        if (e.statusCode == 408 || e.message.contains('timeout')) {
          SnackbarUtils.showError(
            'Payment request timed out. Please check your connection and try again.',
          );
        } else if (e.statusCode >= 500) {
          SnackbarUtils.showError(
            'Payment service temporarily unavailable. Please try again in a few minutes.',
          );
        } else {
          SnackbarUtils.showError('Payment Error: ${e.message}');
        }
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        SnackbarUtils.showError(
          'Network connection failed. Please check your internet and try again.',
        );
      } else {
        SnackbarUtils.showError(
          'Failed to start payment process. Please try again.',
        );
      }

      // Offer alternative payment method
      _showPaymentFailureDialog();
    }
  }

  void _showPaymentFailureDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Issue'),
        content: const Text(
          'We\'re having trouble processing your payment. Would you like to try again or use Cash on Delivery?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              selectedPaymentMethod.value = 'cash_on_delivery';
              initiatePayment();
            },
            child: const Text('Cash on Delivery'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              initiatePayment();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple connectivity check by trying to resolve a DNS
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('Network connectivity check failed: $e');
      return false;
    }
  }

  List<String> _getPaymentChannels() {
    switch (selectedPaymentMethod.value) {
      case 'credit_card':
        return ['card'];
      case 'upi':
        return ['transfer'];
      case 'net_banking':
        return ['bank'];
      default:
        return ['card', 'bank', 'ussd', 'transfer'];
    }
  }

  Future<void> _handlePaymentResult(PaymentResult result) async {
    print('Payment result: $result');

    switch (result) {
      case PaymentResult.success:
        await _processSuccessfulPayment();
        break;
      case PaymentResult.failed:
        _handleFailedPayment();
        break;
      case PaymentResult.cancelled:
        _handleCancelledPayment();
        break;
      case PaymentResult.pending:
        _handlePendingPayment();
        break;
    }
  }

  Future<void> _processSuccessfulPayment() async {
    try {
      isProcessingOrder.value = true;

      // Verify payment one more time
      final verification = await SquadPaymentService.verifyPayment(
        currentTransactionRef.value,
      );

      if (verification.isSuccessful) {
        // Create order with payment details
        final success = await _createOrderWithPaymentDetails(verification);

        if (success) {
          SnackbarUtils.showSuccess('Payment successful! Order confirmed.');
          Get.offAllNamed('/order-confirmation');
        } else {
          SnackbarUtils.showError(
            'Payment successful but order creation failed. Please contact support.',
          );
        }
      } else {
        SnackbarUtils.showWarning(
          'Payment verification failed. Please check your orders or contact support.',
        );
      }
    } catch (e) {
      print('Error processing successful payment: $e');
      SnackbarUtils.showError(
        'Payment completed but verification failed. Please check your orders.',
      );
    } finally {
      isProcessingOrder.value = false;
    }
  }

  Future<bool> _createOrderWithPaymentDetails(
    SquadPaymentVerification verification,
  ) async {
    try {
      // Convert cart items to order items
      final orderItems =
          _cartController.items
              .map(
                (cartItem) => OrderItem(
                  id: '', // Will be generated by database
                  orderId: '', // Will be set by repository
                  productId: cartItem.product.id,
                  quantity: cartItem.quantity,
                  price: cartItem.product.price,
                  selectedSize: cartItem.selectedSize,
                  selectedColor: cartItem.selectedColor,
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      // Create order with Squad payment details
      final success = await _orderController.createOrderWithPayment(
        addressId: selectedAddressId.value,
        paymentMethodId: selectedPaymentMethod.value,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        items: orderItems,
        squadTransactionRef: currentTransactionRef.value,
        squadGatewayRef: verification.gatewayRef,
        paymentStatus: 'completed',
        loyaltyVoucherCode: voucherApplied.value ? voucherCode.value : null,
      );

      if (success) {
        // Clear cart after successful order
        await _cartController.clearCart();

        // Refresh vouchers if one was used
        if (voucherApplied.value) {
          try {
            final loyaltyController = Get.find<LoyaltyController>();
            await loyaltyController.loadVouchers();
            print('CheckoutController: Vouchers refreshed after Squad payment');
          } catch (e) {
            print('CheckoutController: Error refreshing vouchers: $e');
            // Don't fail order if voucher refresh fails
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error creating order with payment details: $e');
      return false;
    }
  }

  void _handleFailedPayment() {
    SnackbarUtils.showError(
      'Payment failed. Please try again or use a different payment method.',
    );
    currentTransactionRef.value = '';
  }

  void _handleCancelledPayment() {
    SnackbarUtils.showInfo(
      'Payment cancelled. Your cart items are still saved.',
    );
    currentTransactionRef.value = '';
    // Webview controller already handles navigation back to checkout
  }

  void _handlePendingPayment() {
    SnackbarUtils.showWarning(
      'Payment is being processed. We will notify you once it\'s confirmed.',
    );
    // Navigate back but don't clear cart yet
    Get.back();
  }

  String getPaymentMethodName(String id) {
    final method = paymentMethods.firstWhere(
      (method) => method['id'] == id,
      orElse: () => {'name': 'Unknown'},
    );
    return method['name'];
  }

  IconData getPaymentMethodIcon(String id) {
    final method = paymentMethods.firstWhere(
      (method) => method['id'] == id,
      orElse: () => {'icon': Icons.payment},
    );
    return method['icon'];
  }

  void reset() {
    selectedAddressId.value = '';
    selectedPaymentMethod.value = 'cash_on_delivery';
    isProcessingOrder.value = false;
    clearVoucher();
  }
}
