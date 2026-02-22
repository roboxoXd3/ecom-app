import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/squad_payment_service.dart';
import '../screens/payment/squad_payment_webview.dart';
import '../../../core/utils/snackbar_utils.dart';

class PaymentWebViewController extends GetxController {
  final String checkoutUrl;
  final String transactionRef;
  final Function(PaymentResult) onPaymentComplete;

  late WebViewController webViewController;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isVerifyingPayment = false.obs;

  Timer? _loadingTimeout;
  bool _isClosing = false;

  PaymentWebViewController({
    required this.checkoutUrl,
    required this.transactionRef,
    required this.onPaymentComplete,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
  }

  @override
  void onClose() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    super.onClose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Checks if the *host* of a URL is a Squad domain.
  /// Using `Uri.parse().host` avoids false positives when Squad domains
  /// appear inside query strings of third-party URLs (like riskified).
  bool _isSquadHost(String url) {
    if (url.isEmpty) return true; // no URL = main frame
    try {
      final host = Uri.parse(url).host;
      return host.endsWith('squadco.com') || host.endsWith('squad.co');
    } catch (_) {
      return false;
    }
  }

  /// Single exit-point. Guards against duplicate calls.
  void _closeWebView(PaymentResult result) {
    if (_isClosing) return;
    _isClosing = true;
    _loadingTimeout?.cancel();
    onPaymentComplete(result);

    // Pop everything until we're back at the checkout screen.
    // Using Navigator directly is more reliable than Get.back() which can
    // silently fail if the route stack is in an unexpected state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = Get.key.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    });
  }

  // ── WebView setup ───────────────────────────────────────────────────

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel(
        'PaymentBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _handleBridgeMessage(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Payment page started: $url');
            isLoading.value = true;
            hasError.value = false;
            _startLoadingTimeout();
          },
          onPageFinished: (String url) {
            print('Payment page finished: $url');
            isLoading.value = false;
            _loadingTimeout?.cancel();
            _handlePageFinished(url);
          },
          onWebResourceError: (WebResourceError error) {
            final failedUrl = error.url ?? '';

            // Only show error UI for Squad's own pages.
            // Third-party resources (riskified, online-metrix, etc.) are
            // silently ignored — they're not critical for the payment.
            if (_isSquadHost(failedUrl)) {
              print('Squad page error: ${error.description}');
              hasError.value = true;
              errorMessage.value = _getUserFriendlyErrorMessage(error);
              isLoading.value = false;
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigationRequest(request);
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  // ── JS Bridge ───────────────────────────────────────────────────────

  void _handleBridgeMessage(String message) {
    print('JS bridge: $message');
    if (message == 'payment_success') {
      _verifyPaymentAndComplete(PaymentResult.success);
    } else if (message == 'payment_failed') {
      _verifyPaymentAndComplete(PaymentResult.failed);
    } else if (message == 'widget_closed' || message == 'payment_cancelled') {
      _closeWebView(PaymentResult.cancelled);
    }
  }

  void _injectSquadBridge() {
    webViewController.runJavaScript('''
      if (!window._bsBridge) {
        window._bsBridge = true;
        window.addEventListener('message', function(e) {
          var d = e.data;
          if (!d) return;
          var t = (typeof d === 'object') ? (d.type || '') : String(d);
          t = t.toLowerCase();
          if (t.indexOf('success') !== -1) {
            PaymentBridge.postMessage('payment_success');
          } else if (t.indexOf('fail') !== -1) {
            PaymentBridge.postMessage('payment_failed');
          } else if (t.indexOf('cancel') !== -1 || t.indexOf('close') !== -1) {
            PaymentBridge.postMessage('widget_closed');
          }
        });
      }
    ''').catchError((_) {});
  }

  // ── Navigation handling ─────────────────────────────────────────────

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url.toLowerCase();

    // Allow all Squad & payment gateway domains
    if (url.contains('squadco.com') ||
        url.contains('squad.co') ||
        url.contains('paystack.co') ||
        url.contains('flutterwave.com') ||
        url.contains('remita.net') ||
        url.contains('interswitchng.com')) {
      return NavigationDecision.navigate;
    }

    // Allow fraud detection / 3DS
    if (url.contains('online-metrix.net') ||
        url.contains('riskified.com') ||
        url.contains('cardinalcommerce.com') ||
        url.contains('about:blank')) {
      return NavigationDecision.navigate;
    }

    // Railway webhook callback
    if (url.contains('railway.app/api/payments/webhook')) {
      _handleCallbackUrl(request.url);
      return NavigationDecision.prevent;
    }

    // Success redirect
    if (url.contains('railway.app/api/payments/success') ||
        url.contains('/payment/success')) {
      _verifyPaymentAndComplete(PaymentResult.success);
      return NavigationDecision.prevent;
    }

    // Failure redirect
    if (url.contains('railway.app/api/payments/failed') ||
        url.contains('/payment/failed')) {
      _verifyPaymentAndComplete(PaymentResult.failed);
      return NavigationDecision.prevent;
    }

    // External link
    if (url.startsWith('http')) {
      _launchExternalUrl(request.url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _handlePageFinished(String url) {
    final lc = url.toLowerCase();

    // Inject bridge only on Squad pages
    if (_isSquadHost(url)) {
      _injectSquadBridge();
    }

    // URL-based result detection
    if (lc.contains('/payment/success') || lc.contains('status=successful')) {
      _verifyPaymentAndComplete(PaymentResult.success);
    }
  }

  void _handleCallbackUrl(String url) {
    _verifyPaymentAndComplete(PaymentResult.pending);
  }

  // ── Payment verification ────────────────────────────────────────────

  Future<void> _verifyPaymentAndComplete(PaymentResult presumedResult) async {
    if (isVerifyingPayment.value || _isClosing) return;

    try {
      isVerifyingPayment.value = true;
      await Future.delayed(const Duration(seconds: 2));

      final verification = await SquadPaymentService.verifyPayment(
        transactionRef,
      );

      if (verification.isSuccessful) {
        SnackbarUtils.showSuccess('Payment completed successfully!');
        _closeWebView(PaymentResult.success);
      } else if (verification.isFailed) {
        SnackbarUtils.showError('Payment failed. Please try again.');
        _closeWebView(PaymentResult.failed);
      } else {
        SnackbarUtils.showInfo('Payment is being processed...');
        _closeWebView(PaymentResult.pending);
      }
    } catch (e) {
      print('Payment verification error: $e');
      if (presumedResult == PaymentResult.success) {
        SnackbarUtils.showWarning(
          'Payment may have completed. Please check your orders.',
        );
        _closeWebView(PaymentResult.success);
      } else {
        SnackbarUtils.showError('Unable to verify payment status.');
        _closeWebView(PaymentResult.failed);
      }
    } finally {
      isVerifyingPayment.value = false;
    }
  }

  // ── User actions ────────────────────────────────────────────────────

  void cancelPayment() {
    _closeWebView(PaymentResult.cancelled);
  }

  void refreshPage() {
    hasError.value = false;
    errorMessage.value = '';
    isLoading.value = true;
    _isClosing = false;
    Future.delayed(const Duration(milliseconds: 300), () {
      webViewController.reload();
    });
  }

  // ── Internals ───────────────────────────────────────────────────────

  String _getUserFriendlyErrorMessage(WebResourceError error) {
    final desc = error.description.toLowerCase();
    if (desc.contains('err_internet_disconnected')) {
      return 'No internet connection. Please connect and try again.';
    } else if (desc.contains('err_name_not_resolved')) {
      return 'Unable to reach the payment server.';
    } else if (desc.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (desc.contains('ssl')) {
      return 'Secure connection failed.';
    }
    return 'Unable to load the payment page. Please try again.';
  }

  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 30), () {
      if (isLoading.value && !hasError.value) {
        hasError.value = true;
        errorMessage.value = 'Payment page took too long to load.';
        isLoading.value = false;
      }
    });
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching external URL: $e');
    }
  }
}
