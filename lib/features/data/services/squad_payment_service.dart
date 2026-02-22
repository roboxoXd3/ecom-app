import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SquadPaymentService {
  static final _api = ApiClient.instance;

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
    try {
      final response = await _api.post('/payments/initiate/', data: {
        'amount': amount,
        'email': email,
        'currency': currency,
        if (metadata != null && metadata['order_id'] != null)
          'order_id': metadata['order_id'],
      });

      // Log the raw response so we can see Django's exact shape
      print('Squad initiate raw response: ${response.data}');

      final raw = response.data;
      String? checkoutUrl;
      String? transactionRef;
      String message = 'Payment initiated';

      if (raw is Map<String, dynamic>) {
        message = raw['message']?.toString() ?? message;

        // Django may nest payment data under 'data' key as a Map or directly
        final nested = raw['data'];
        final paymentData = nested is Map<String, dynamic> ? nested : raw;

        checkoutUrl = paymentData['checkout_url']?.toString();
        transactionRef = paymentData['transaction_ref']?.toString();

        // Some Django responses put checkout_url at top level
        checkoutUrl ??= raw['checkout_url']?.toString();
        transactionRef ??= raw['transaction_ref']?.toString();
      }

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw SquadPaymentException(
          'No checkout URL returned from payment service. Response: $raw',
          500,
        );
      }

      return SquadPaymentResponse(
        success: true,
        message: message,
        checkoutUrl: checkoutUrl,
        transactionRef: transactionRef,
        amount: amount,
        currency: currency,
      );
    } on DioException catch (e) {
      print('Squad initiate DioException: ${e.response?.data}');
      final responseData = e.response?.data;
      String msg = 'Payment initiation failed';
      if (responseData is Map) {
        msg = responseData['detail']?.toString() ??
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            msg;
      }
      throw SquadPaymentException(msg, e.response?.statusCode ?? 500);
    } catch (e) {
      if (e is SquadPaymentException) rethrow;
      throw SquadPaymentException('Network error: ${e.toString()}', 500);
    }
  }

  static Future<SquadPaymentVerification> verifyPayment(
    String transactionRef,
  ) async {
    try {
      final response = await _api.get('/payments/verify/$transactionRef/');
      final data = response.data as Map<String, dynamic>;

      return SquadPaymentVerification(
        success: data['status'] == 'success',
        message: data['message'] ?? '',
        transactionRef: transactionRef,
        status: data['status']?.toString(),
        gatewayRef: data['gateway_ref']?.toString(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ??
          'Payment verification failed';
      throw SquadPaymentException(msg, e.response?.statusCode ?? 500);
    } catch (e) {
      throw SquadPaymentException('Verification error: ${e.toString()}', 500);
    }
  }

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
