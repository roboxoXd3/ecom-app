import 'dart:async';
import 'package:get/get.dart';
import 'squad_payment_service.dart';
import '../repositories/order_repository.dart';
import '../../presentation/controllers/order_controller.dart';
import '../../../core/utils/snackbar_utils.dart';

class PaymentVerificationService {
  static final OrderRepository _orderRepository = OrderRepository();
  static Timer? _verificationTimer;
  static final Set<String> _pendingVerifications = <String>{};

  /// Start periodic verification for pending payments
  static void startPeriodicVerification() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _verifyPendingPayments(),
    );
  }

  /// Stop periodic verification
  static void stopPeriodicVerification() {
    _verificationTimer?.cancel();
    _verificationTimer = null;
  }

  /// Add a transaction to pending verification queue
  static void addPendingVerification(String transactionRef) {
    _pendingVerifications.add(transactionRef);
    print('Added $transactionRef to pending verification queue');
  }

  /// Remove a transaction from pending verification queue
  static void removePendingVerification(String transactionRef) {
    _pendingVerifications.remove(transactionRef);
    print('Removed $transactionRef from pending verification queue');
  }

  /// Verify a specific payment
  static Future<PaymentVerificationResult> verifyPayment(
    String transactionRef,
  ) async {
    try {
      print('Verifying payment for transaction: $transactionRef');

      final verification = await SquadPaymentService.verifyPayment(
        transactionRef,
      );

      if (verification.isSuccessful) {
        await _handleSuccessfulPayment(transactionRef, verification);
        removePendingVerification(transactionRef);
        return PaymentVerificationResult.success(verification);
      } else if (verification.isFailed) {
        await _handleFailedPayment(transactionRef, verification);
        removePendingVerification(transactionRef);
        return PaymentVerificationResult.failed(verification);
      } else {
        // Still pending
        addPendingVerification(transactionRef);
        return PaymentVerificationResult.pending(verification);
      }
    } catch (e) {
      print('Error verifying payment $transactionRef: $e');
      return PaymentVerificationResult.error(e.toString());
    }
  }

  /// Verify all pending payments
  static Future<void> _verifyPendingPayments() async {
    if (_pendingVerifications.isEmpty) return;

    print('Verifying ${_pendingVerifications.length} pending payments...');

    final pendingList = _pendingVerifications.toList();

    for (final transactionRef in pendingList) {
      try {
        await verifyPayment(transactionRef);
        // Small delay between verifications to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Error in periodic verification for $transactionRef: $e');
      }
    }
  }

  /// Handle successful payment verification
  static Future<void> _handleSuccessfulPayment(
    String transactionRef,
    SquadPaymentVerification verification,
  ) async {
    try {
      // Find order by transaction reference and update payment status
      final orderController = Get.find<OrderController>();
      final orders = orderController.orders;

      final order = orders.firstWhereOrNull(
        (o) => o.squadTransactionRef == transactionRef,
      );

      if (order != null) {
        await orderController.updatePaymentStatus(
          orderId: order.id,
          paymentStatus: 'completed',
          squadGatewayRef: verification.gatewayRef,
          escrowStatus: 'held', // Hold in escrow until delivery
        );

        print('Payment verified and order updated: ${order.id}');

        // Show success notification if app is active
        if (Get.isRegistered<OrderController>()) {
          SnackbarUtils.showSuccess(
            'Payment confirmed for order #${order.id.substring(0, 8)}',
          );
        }
      } else {
        print('Order not found for transaction: $transactionRef');
      }
    } catch (e) {
      print('Error handling successful payment: $e');
    }
  }

  /// Handle failed payment verification
  static Future<void> _handleFailedPayment(
    String transactionRef,
    SquadPaymentVerification verification,
  ) async {
    try {
      final orderController = Get.find<OrderController>();
      final orders = orderController.orders;

      final order = orders.firstWhereOrNull(
        (o) => o.squadTransactionRef == transactionRef,
      );

      if (order != null) {
        await orderController.updatePaymentStatus(
          orderId: order.id,
          paymentStatus: 'failed',
          squadGatewayRef: verification.gatewayRef,
        );

        print('Payment failed for order: ${order.id}');

        // Show failure notification if app is active
        if (Get.isRegistered<OrderController>()) {
          SnackbarUtils.showError(
            'Payment failed for order #${order.id.substring(0, 8)}',
          );
        }
      }
    } catch (e) {
      print('Error handling failed payment: $e');
    }
  }

  /// Handle webhook notification from Squad
  static Future<void> handleWebhookNotification(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      final transactionRef = webhookData['transaction_ref'] as String?;
      final status = webhookData['transaction_status'] as String?;

      if (transactionRef == null || status == null) {
        print('Invalid webhook data: missing transaction_ref or status');
        return;
      }

      print(
        'Received webhook for transaction: $transactionRef, status: $status',
      );

      // Verify the payment to get complete details
      await verifyPayment(transactionRef);
    } catch (e) {
      print('Error handling webhook notification: $e');
    }
  }

  /// Initialize the service
  static void initialize() {
    startPeriodicVerification();
    print('Payment verification service initialized');
  }

  /// Dispose the service
  static void dispose() {
    stopPeriodicVerification();
    _pendingVerifications.clear();
    print('Payment verification service disposed');
  }
}

class PaymentVerificationResult {
  final PaymentVerificationStatus status;
  final SquadPaymentVerification? verification;
  final String? errorMessage;

  PaymentVerificationResult._({
    required this.status,
    this.verification,
    this.errorMessage,
  });

  factory PaymentVerificationResult.success(
    SquadPaymentVerification verification,
  ) {
    return PaymentVerificationResult._(
      status: PaymentVerificationStatus.success,
      verification: verification,
    );
  }

  factory PaymentVerificationResult.failed(
    SquadPaymentVerification verification,
  ) {
    return PaymentVerificationResult._(
      status: PaymentVerificationStatus.failed,
      verification: verification,
    );
  }

  factory PaymentVerificationResult.pending(
    SquadPaymentVerification verification,
  ) {
    return PaymentVerificationResult._(
      status: PaymentVerificationStatus.pending,
      verification: verification,
    );
  }

  factory PaymentVerificationResult.error(String errorMessage) {
    return PaymentVerificationResult._(
      status: PaymentVerificationStatus.error,
      errorMessage: errorMessage,
    );
  }

  bool get isSuccess => status == PaymentVerificationStatus.success;
  bool get isFailed => status == PaymentVerificationStatus.failed;
  bool get isPending => status == PaymentVerificationStatus.pending;
  bool get isError => status == PaymentVerificationStatus.error;
}

enum PaymentVerificationStatus { success, failed, pending, error }
