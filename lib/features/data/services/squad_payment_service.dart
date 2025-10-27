import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

class SquadPaymentService {
  static String get baseUrl =>
      dotenv.env['SQUAD_BASE_URL'] ?? 'https://sandbox-api-d.squadco.com';
  static String get secretKey => dotenv.env['SQUAD_SECRET_KEY'] ?? '';
  static String get publicKey => dotenv.env['SQUAD_PUBLIC_KEY'] ?? '';
  static String get webhookSecret => dotenv.env['SQUAD_WEBHOOK_SECRET'] ?? '';

  /// Convert amount to smallest currency unit
  static int _convertToSmallestUnit(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN': // Nigerian Naira - kobo (1/100)
      case 'USD': // US Dollar - cents (1/100)
      case 'EUR': // Euro - cents (1/100)
      case 'GBP': // British Pound - pence (1/100)
      case 'CAD': // Canadian Dollar - cents (1/100)
      case 'AUD': // Australian Dollar - cents (1/100)
      case 'INR': // Indian Rupee - paise (1/100)
        return (amount * 100).toInt();
      case 'JPY': // Japanese Yen - no subdivision
      case 'KRW': // Korean Won - no subdivision
        return amount.toInt();
      default:
        // Default to 2 decimal places for unknown currencies
        return (amount * 100).toInt();
    }
  }

  /// Retry logic for network requests
  static Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        print('Request attempt $attempts failed: $e');

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw SquadPaymentException('Max retries exceeded', 500);
  }

  /// Initiate payment and get checkout URL
  static Future<SquadPaymentResponse> initiatePayment({
    required double amount,
    required String email,
    required String transactionRef,
    String currency = 'NGN',
    String? callbackUrl,
    String? redirectUrl,
    List<String>? paymentChannels,
    Map<String, dynamic>? metadata,
  }) async {
    return await _retryRequest(
      () => _initiatePaymentRequest(
        amount: amount,
        email: email,
        transactionRef: transactionRef,
        currency: currency,
        callbackUrl: callbackUrl,
        redirectUrl: redirectUrl,
        paymentChannels: paymentChannels,
        metadata: metadata,
      ),
    );
  }

  static Future<SquadPaymentResponse> _initiatePaymentRequest({
    required double amount,
    required String email,
    required String transactionRef,
    String currency = 'NGN',
    String? callbackUrl,
    String? redirectUrl,
    List<String>? paymentChannels,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/transaction/initiate');

      final body = {
        'amount': _convertToSmallestUnit(
          amount,
          currency,
        ), // Convert based on currency
        'email': email,
        'currency': currency,
        'initiate_type': 'inline',
        'transaction_ref': transactionRef,
        if (callbackUrl != null) 'callback_url': callbackUrl,
        // Squad API redirect URL - try without redirect parameter first
        // if (redirectUrl != null) 'return_url': redirectUrl,
        if (paymentChannels != null) 'payment_channels': paymentChannels,
        if (metadata != null) 'metadata': metadata,
      };

      print('Squad Payment Request: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $secretKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'BeSmartApp/1.0 (Flutter)',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw SquadPaymentException(
                'Request timeout. Please try again.',
                408,
              );
            },
          );

      print(
        'Squad Payment Response: ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        return SquadPaymentResponse.fromJson(responseData);
      } else {
        throw SquadPaymentException(
          responseData['message'] ?? 'Payment initiation failed',
          responseData['status'] ?? response.statusCode,
        );
      }
    } catch (e) {
      print('Squad Payment Error: $e');
      if (e is SquadPaymentException) rethrow;
      throw SquadPaymentException('Network error: ${e.toString()}', 500);
    }
  }

  /// Verify payment status
  static Future<SquadPaymentVerification> verifyPayment(
    String transactionRef,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/transaction/verify/$transactionRef');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $secretKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'BeSmartApp/1.0 (Flutter)',
            },
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw SquadPaymentException(
                'Verification timeout. Please try again.',
                408,
              );
            },
          );

      print(
        'Squad Verification Response: ${response.statusCode} - ${response.body}',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return SquadPaymentVerification.fromJson(responseData);
      } else {
        throw SquadPaymentException(
          responseData['message'] ?? 'Payment verification failed',
          responseData['status'] ?? response.statusCode,
        );
      }
    } catch (e) {
      print('Squad Verification Error: $e');
      if (e is SquadPaymentException) rethrow;
      throw SquadPaymentException('Verification error: ${e.toString()}', 500);
    }
  }

  /// Validate webhook signature
  static bool validateWebhookSignature(
    Map<String, dynamic> payload,
    String signature,
  ) {
    try {
      final payloadString = jsonEncode(payload);
      final key = utf8.encode(webhookSecret);
      final bytes = utf8.encode(payloadString);

      final hmacSha512 = Hmac(sha512, key);
      final digest = hmacSha512.convert(bytes);
      final expectedSignature = digest.toString();

      return expectedSignature.toLowerCase() == signature.toLowerCase();
    } catch (e) {
      print('Webhook signature validation error: $e');
      return false;
    }
  }

  /// Generate unique transaction reference
  static String generateTransactionRef() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BESMART_${timestamp}_${DateTime.now().microsecond}';
  }
}

class SquadPaymentResponse {
  final bool success;
  final String message;
  final String? checkoutUrl;
  final String? transactionRef;
  final double? amount;
  final String? currency;
  final Map<String, dynamic>? merchantInfo;

  SquadPaymentResponse({
    required this.success,
    required this.message,
    this.checkoutUrl,
    this.transactionRef,
    this.amount,
    this.currency,
    this.merchantInfo,
  });

  factory SquadPaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return SquadPaymentResponse(
      success: json['status'] == 200,
      message: json['message'] ?? '',
      checkoutUrl: data?['checkout_url'],
      transactionRef: data?['transaction_ref'],
      amount: data?['transaction_amount']?.toDouble(),
      currency: data?['currency'],
      merchantInfo: data?['merchant_info'],
    );
  }
}

class SquadPaymentVerification {
  final bool success;
  final String message;
  final String? transactionRef;
  final String? status;
  final double? amount;
  final String? email;
  final String? currency;
  final String? transactionType;
  final String? gatewayRef;
  final DateTime? createdAt;

  SquadPaymentVerification({
    required this.success,
    required this.message,
    this.transactionRef,
    this.status,
    this.amount,
    this.email,
    this.currency,
    this.transactionType,
    this.gatewayRef,
    this.createdAt,
  });

  factory SquadPaymentVerification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return SquadPaymentVerification(
      success: json['success'] == true,
      message: json['message'] ?? '',
      transactionRef: data?['transaction_ref'],
      status: data?['transaction_status'],
      amount: data?['transaction_amount']?.toDouble(),
      email: data?['email'],
      currency: data?['transaction_currency_id'],
      transactionType: data?['transaction_type'],
      gatewayRef: data?['gateway_transaction_ref'],
      createdAt:
          data?['created_at'] != null
              ? DateTime.tryParse(data!['created_at'])
              : null,
    );
  }

  bool get isSuccessful => status?.toLowerCase() == 'success';
  bool get isPending => status?.toLowerCase() == 'pending';
  bool get isFailed => status?.toLowerCase() == 'failed';
}

class SquadPaymentException implements Exception {
  final String message;
  final int statusCode;

  SquadPaymentException(this.message, this.statusCode);

  @override
  String toString() => 'SquadPaymentException: $message (Status: $statusCode)';
}

enum SquadPaymentStatus { pending, success, failed, abandoned }

extension SquadPaymentStatusExtension on SquadPaymentStatus {
  static SquadPaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return SquadPaymentStatus.success;
      case 'failed':
        return SquadPaymentStatus.failed;
      case 'abandoned':
        return SquadPaymentStatus.abandoned;
      default:
        return SquadPaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case SquadPaymentStatus.pending:
        return 'Pending';
      case SquadPaymentStatus.success:
        return 'Success';
      case SquadPaymentStatus.failed:
        return 'Failed';
      case SquadPaymentStatus.abandoned:
        return 'Abandoned';
    }
  }
}
