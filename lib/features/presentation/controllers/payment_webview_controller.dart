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
  int _retryCount = 0;
  static const int _maxRetries = 3;

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

  // ignore: unused_element
  void _handleJavaScriptMessage(String message) {
    try {
      print('JavaScript message received: $message');

      // Handle payment status messages from JavaScript
      if (message.contains('payment_success')) {
        _logPaymentEvent('js_payment_success', {'message': message});
        _verifyPaymentAndComplete(PaymentResult.success);
      } else if (message.contains('payment_failed')) {
        _logPaymentEvent('js_payment_failed', {'message': message});
        _verifyPaymentAndComplete(PaymentResult.failed);
      } else if (message.contains('payment_cancelled')) {
        _logPaymentEvent('js_payment_cancelled', {'message': message});
        onPaymentComplete(PaymentResult.cancelled);
        Get.back(); // Close the webview screen
      } else if (message.contains('console_error')) {
        _logPaymentEvent('js_console_error', {'message': message});
        // Don't fail on console errors, just log them
      }
    } catch (e) {
      print('Error handling JavaScript message: $e');
    }
  }

  String _getUserFriendlyErrorMessage(WebResourceError error) {
    switch (error.errorType) {
      case WebResourceErrorType.hostLookup:
        return 'Unable to connect to payment server. Please check your internet connection.';
      case WebResourceErrorType.timeout:
        return 'Payment page took too long to load. Please try again.';
      case WebResourceErrorType.connect:
        return 'Connection failed. Please check your internet connection and try again.';
      case WebResourceErrorType.authentication:
        return 'Authentication error. Please try again.';
      case WebResourceErrorType.unsafeResource:
        return 'Security error. Please contact support.';
      default:
        if (error.description.toLowerCase().contains('net::err_failed')) {
          return 'Network connection failed. Please check your internet and try again.';
        } else if (error.description.toLowerCase().contains(
          'net::err_internet_disconnected',
        )) {
          return 'No internet connection. Please connect to the internet and try again.';
        } else if (error.description.toLowerCase().contains(
          'net::err_name_not_resolved',
        )) {
          return 'Unable to reach payment server. Please try again later.';
        } else if (error.description.toLowerCase().contains('dns')) {
          return 'DNS resolution failed. Please check your network connection.';
        } else if (error.description.toLowerCase().contains('timeout')) {
          return 'Connection timed out. Please try again.';
        } else if (error.description.toLowerCase().contains('ssl')) {
          return 'Secure connection failed. Please try again.';
        }
        return 'Payment page failed to load. Please try again.';
    }
  }

  void _initializeWebView() {
    webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading progress if needed
              },
              onPageStarted: (String url) {
                print('Payment page started loading: $url');
                isLoading.value = true;
                hasError.value = false;

                // Log page load start for debugging
                _logPaymentEvent('page_load_start', {'url': url});

                // Start loading timeout
                _startLoadingTimeout();
              },
              onPageFinished: (String url) {
                print('Payment page finished loading: $url');
                isLoading.value = false;
                _cancelLoadingTimeout();
                _handlePageFinished(url);
              },
              onWebResourceError: (WebResourceError error) {
                print('Payment page error: ${error.description}');
                print('Error type: ${error.errorType}');
                print('Error code: ${error.errorCode}');
                print('Failed URL: ${error.url}');

                // Log the error for debugging
                _logPaymentEvent('webview_error', {
                  'error_description': error.description,
                  'error_type': error.errorType.toString(),
                  'error_code': error.errorCode,
                  'failed_url': error.url ?? 'unknown',
                });

                // Only show error for main page failures, not resource failures
                if (error.url == null || error.url!.contains('squadco.com')) {
                  String userFriendlyMessage = _getUserFriendlyErrorMessage(
                    error,
                  );
                  hasError.value = true;
                  errorMessage.value = userFriendlyMessage;
                  isLoading.value = false;
                } else {
                  // For resource errors (like third-party scripts), just log but don't fail
                  print('Ignoring resource error for: ${error.url}');
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation request: ${request.url}');
                return _handleNavigationRequest(request);
              },
            ),
          )
          ..loadRequest(Uri.parse(checkoutUrl))
          ..runJavaScript('''
            console.log('Payment WebView JavaScript initialized');
            
            // Disable WebGL to prevent errors
            if (window.WebGLRenderingContext) {
              const originalGetContext = HTMLCanvasElement.prototype.getContext;
              HTMLCanvasElement.prototype.getContext = function(contextType, ...args) {
                if (contextType === 'webgl' || contextType === 'experimental-webgl') {
                  console.log('WebGL context blocked to prevent errors');
                  return null;
                }
                return originalGetContext.apply(this, [contextType, ...args]);
              };
            }
            
            // Override console.error to catch and report errors
            const originalConsoleError = console.error;
            console.error = function(...args) {
              originalConsoleError.apply(console, args);
              try {
                if (window.PaymentHandler) {
                  PaymentHandler.postMessage('console_error: ' + args.join(' '));
                }
              } catch(e) {
                // Ignore if PaymentHandler not available
              }
            };
            
            // Add payment status handlers
            window.addEventListener('message', function(event) {
              console.log('Payment message received:', event.data);
              if (event.data && event.data.type) {
                if (event.data.type === 'payment_success') {
                  PaymentHandler.postMessage('payment_success');
                } else if (event.data.type === 'payment_failed') {
                  PaymentHandler.postMessage('payment_failed');
                } else if (event.data.type === 'payment_cancelled') {
                  PaymentHandler.postMessage('payment_cancelled');
                }
              }
            });
            
            // Monitor for payment completion via URL changes
            let lastUrl = window.location.href;
            setInterval(function() {
              if (window.location.href !== lastUrl) {
                lastUrl = window.location.href;
                console.log('URL changed to:', lastUrl);
                
                if (lastUrl.includes('success') || lastUrl.includes('completed')) {
                  PaymentHandler.postMessage('payment_success');
                } else if (lastUrl.includes('failed') || lastUrl.includes('error')) {
                  PaymentHandler.postMessage('payment_failed');
                } else if (lastUrl.includes('cancel')) {
                  PaymentHandler.postMessage('payment_cancelled');
                }
              }
            }, 1000);
          ''');
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url.toLowerCase();

    // Allow Squad domains and payment gateways
    if (url.contains('squadco.com') ||
        url.contains('squad.co') ||
        url.contains('paystack.co') ||
        url.contains('flutterwave.com') ||
        url.contains('remita.net') ||
        url.contains('interswitchng.com')) {
      return NavigationDecision.navigate;
    }

    // Allow fraud detection and security URLs (must load silently for payment to work)
    if (url.contains(
          'online-metrix.net',
        ) || // ThreatMetrix device fingerprinting
        url.contains('cardinalcommerce.com') || // Cardinal Commerce 3D Secure
        url.contains('centinelapistag.cardinalcommerce.com') || // Cardinal API
        url.contains('about:blank')) {
      // Empty iframes used by fraud detection
      print('Allowing security URL: ${request.url}');
      return NavigationDecision.navigate; // Load silently in WebView
    }

    // Handle callback URLs (webhook)
    if (url.contains(
      'ecomadmin-production.up.railway.app/api/payments/webhook',
    )) {
      _handleCallbackUrl(request.url);
      return NavigationDecision.prevent;
    }

    // Handle success redirect URLs
    if (url.contains(
          'ecomadmin-production.up.railway.app/api/payments/success',
        ) ||
        url.contains('success')) {
      print('Success redirect detected: ${request.url}');
      _verifyPaymentAndComplete(PaymentResult.success);
      return NavigationDecision.prevent;
    }

    // Handle failure redirect URLs
    if (url.contains(
          'ecomadmin-production.up.railway.app/api/payments/failed',
        ) ||
        url.contains('failed') ||
        url.contains('cancelled')) {
      print('Failure redirect detected: ${request.url}');
      _verifyPaymentAndComplete(PaymentResult.failed);
      return NavigationDecision.prevent;
    }

    // Handle external links (but not security URLs)
    if (url.startsWith('http') && !url.contains('squadco.com')) {
      _launchExternalUrl(request.url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _handlePageFinished(String url) {
    final lowercaseUrl = url.toLowerCase();

    _logPaymentEvent('page_finished', {'url': url});

    // Check for success/failure indicators in URL
    if (lowercaseUrl.contains('success') ||
        lowercaseUrl.contains('completed')) {
      _verifyPaymentAndComplete(PaymentResult.success);
    } else if (lowercaseUrl.contains('failed') ||
        lowercaseUrl.contains('error')) {
      _verifyPaymentAndComplete(PaymentResult.failed);
    } else if (lowercaseUrl.contains('cancelled')) {
      onPaymentComplete(PaymentResult.cancelled);
      Get.back(); // Close the webview screen
    } else {
      // For Squad payment pages, check page content for success indicators
      _checkPageContentForSuccess();
    }
  }

  void _checkPageContentForSuccess() {
    try {
      webViewController.runJavaScript('''
        // Check for success indicators in the page
        const successIndicators = [
          'payment successful',
          'redirecting in',
          'payment completed',
          'transaction successful'
        ];
        
        const pageText = document.body.innerText.toLowerCase();
        console.log('Page content check:', pageText);
        
        const hasSuccessIndicator = successIndicators.some(indicator => 
          pageText.includes(indicator)
        );
        
        if (hasSuccessIndicator) {
          console.log('Success indicator found in page content');
          PaymentHandler.postMessage('payment_success');
          
          // Also check for redirect countdown
          const redirectMatch = pageText.match(/redirecting in (\\d+)/);
          if (redirectMatch) {
            const seconds = parseInt(redirectMatch[1]);
            console.log('Redirect countdown detected:', seconds, 'seconds');
            
            // Wait for the countdown and then trigger success
            setTimeout(() => {
              PaymentHandler.postMessage('payment_success');
            }, (seconds + 1) * 1000);
          }
        }
      ''');
    } catch (e) {
      print('Error checking page content: $e');
    }
  }

  void _handleCallbackUrl(String url) {
    print('Handling callback URL: $url');

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    // Extract transaction reference from URL if available
    final urlTransactionRef =
        params['transaction_ref'] ?? params['ref'] ?? params['reference'];

    if (urlTransactionRef != null && urlTransactionRef == transactionRef) {
      // Check URL for success/failure indicators
      if (url.toLowerCase().contains('success')) {
        _verifyPaymentAndComplete(PaymentResult.success);
      } else if (url.toLowerCase().contains('failed')) {
        _verifyPaymentAndComplete(PaymentResult.failed);
      } else {
        // Verify payment status
        _verifyPaymentAndComplete(PaymentResult.pending);
      }
    } else {
      // Generic callback handling
      _verifyPaymentAndComplete(PaymentResult.pending);
    }
  }

  Future<void> _verifyPaymentAndComplete(PaymentResult presumedResult) async {
    if (isVerifyingPayment.value) return;

    try {
      isVerifyingPayment.value = true;

      // Wait a moment for payment to be processed
      await Future.delayed(const Duration(seconds: 2));

      final verification = await SquadPaymentService.verifyPayment(
        transactionRef,
      );

      PaymentResult finalResult;
      if (verification.isSuccessful) {
        finalResult = PaymentResult.success;
        SnackbarUtils.showSuccess('Payment completed successfully!');
      } else if (verification.isFailed) {
        finalResult = PaymentResult.failed;
        SnackbarUtils.showError('Payment failed. Please try again.');
      } else {
        finalResult = PaymentResult.pending;
        SnackbarUtils.showInfo('Payment is being processed...');
      }

      onPaymentComplete(finalResult);
      Get.back();
    } catch (e) {
      print('Payment verification error: $e');

      // If verification fails but we have a success indicator, assume success
      if (presumedResult == PaymentResult.success) {
        SnackbarUtils.showWarning(
          'Payment may have completed. Please check your orders.',
        );
        onPaymentComplete(PaymentResult.success);
      } else {
        SnackbarUtils.showError('Unable to verify payment status.');
        onPaymentComplete(PaymentResult.failed);
      }

      Get.back();
    } finally {
      isVerifyingPayment.value = false;
    }
  }

  void refreshPage() {
    hasError.value = false;
    errorMessage.value = '';
    isLoading.value = true;

    // Add a small delay before reloading to ensure state is reset
    Future.delayed(const Duration(milliseconds: 500), () {
      webViewController.reload();
    });
  }

  void retryWithFallback() {
    hasError.value = false;
    errorMessage.value = '';
    isLoading.value = true;

    _logPaymentEvent('retry_payment', {'checkout_url': checkoutUrl});

    // Clear any cached data and try again
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Clear WebView cache
        await webViewController.clearCache();
        await webViewController.clearLocalStorage();

        // Reload with fresh request
        await webViewController.loadRequest(Uri.parse(checkoutUrl));

        // Re-inject JavaScript after a delay
        Future.delayed(const Duration(seconds: 2), () {
          _injectPaymentJavaScript();
        });
      } catch (e) {
        print('Error during retry: $e');
        hasError.value = true;
        errorMessage.value = 'Failed to retry payment. Please try again.';
        isLoading.value = false;
      }
    });
  }

  void _injectPaymentJavaScript() {
    try {
      webViewController.runJavaScript('''
        console.log('Re-injecting payment JavaScript');
        
        // Monitor for payment completion via URL changes
        if (!window.paymentMonitorActive) {
          window.paymentMonitorActive = true;
          let lastUrl = window.location.href;
          
          const checkUrl = () => {
            if (window.location.href !== lastUrl) {
              lastUrl = window.location.href;
              console.log('URL changed to:', lastUrl);
              
              if (lastUrl.includes('success') || lastUrl.includes('completed')) {
                if (window.PaymentHandler) PaymentHandler.postMessage('payment_success');
              } else if (lastUrl.includes('failed') || lastUrl.includes('error')) {
                if (window.PaymentHandler) PaymentHandler.postMessage('payment_failed');
              } else if (lastUrl.includes('cancel')) {
                if (window.PaymentHandler) PaymentHandler.postMessage('payment_cancelled');
              }
            }
          };
          
          setInterval(checkUrl, 1000);
        }
      ''');
    } catch (e) {
      print('Error injecting JavaScript: $e');
    }
  }

  void _startLoadingTimeout() {
    _cancelLoadingTimeout();
    _loadingTimeout = Timer(const Duration(seconds: 30), () {
      if (isLoading.value && !hasError.value) {
        print('Payment page loading timeout');
        _logPaymentEvent('loading_timeout', {'retry_count': _retryCount});

        if (_retryCount < _maxRetries) {
          _retryCount++;
          print('Auto-retrying payment page load (attempt $_retryCount)');
          retryWithFallback();
        } else {
          hasError.value = true;
          errorMessage.value =
              'Payment page took too long to load. Please try again.';
          isLoading.value = false;
        }
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
  }

  void _logPaymentEvent(String event, Map<String, dynamic> data) {
    print('Payment Event: $event - Data: $data');
    // Here you could add analytics logging if needed
  }

  @override
  void onClose() {
    _cancelLoadingTimeout();
    super.onClose();
  }

  void cancelPayment() {
    _logPaymentEvent('payment_cancelled_by_user', {
      'transaction_ref': transactionRef,
    });
    onPaymentComplete(PaymentResult.cancelled);
    Get.back(); // Close the webview screen
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
