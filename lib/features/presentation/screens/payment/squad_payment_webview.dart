import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controllers/payment_webview_controller.dart';
import '../../../../core/theme/app_theme.dart';

class SquadPaymentWebView extends StatelessWidget {
  final String checkoutUrl;
  final String transactionRef;
  final Function(PaymentResult) onPaymentComplete;

  const SquadPaymentWebView({
    super.key,
    required this.checkoutUrl,
    required this.transactionRef,
    required this.onPaymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PaymentWebViewController(
        checkoutUrl: checkoutUrl,
        transactionRef: transactionRef,
        onPaymentComplete: onPaymentComplete,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context, controller),
        ),
        actions: [
          Obx(
            () =>
                controller.isLoading.value
                    ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: controller.refreshPage,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Obx(
            () =>
                controller.isLoading.value
                    ? const LinearProgressIndicator(
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    )
                    : const SizedBox.shrink(),
          ),

          // Payment info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secure payment powered by Squad',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Ref: ${transactionRef.substring(transactionRef.length - 8)}',
                  style: TextStyle(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: Obx(() {
              if (controller.hasError.value) {
                return _buildErrorView(controller);
              }

              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: WebViewWidget(controller: controller.webViewController),
              );
            }),
          ),

          // Bottom info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete your payment securely. Do not close this page until payment is confirmed.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(PaymentWebViewController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Payment Page Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: controller.refreshPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.retryWithFallback,
                  child: Text(
                    'Try Alternative Method',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    PaymentWebViewController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Payment'),
            content: const Text(
              'Are you sure you want to cancel this payment? Your order will not be processed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue Payment'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.cancelPayment();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
    );
  }
}

enum PaymentResult { success, failed, cancelled, pending }

class PaymentResultData {
  final PaymentResult result;
  final String transactionRef;
  final String? message;
  final Map<String, dynamic>? data;

  PaymentResultData({
    required this.result,
    required this.transactionRef,
    this.message,
    this.data,
  });
}
