import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRepository {
  final _api = ApiClient.instance;

  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    final response = await _api.get('/payments/methods/');
    final results = ApiClient.unwrapResults(response.data);
    return results
        .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentMethod?> addPaymentMethod({
    required String userId,
    required String type,
    required String displayName,
    String? last4,
    String? cardBrand,
    String? expiryMonth,
    String? expiryYear,
  }) async {
    try {
      final response = await _api.post('/payments/methods/', data: {
        'card_type': cardBrand ?? type,
        'card_holder_name': displayName,
        'card_number': last4,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'is_default': false,
      });

      return PaymentMethod.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error adding payment method: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod method) async {
    await _api.patch('/payments/methods/${method.id}/', data: {
      'card_type': method.type,
      'card_holder_name': method.displayName,
      'card_number': method.last4,
      'expiry_month': method.expiryMonth,
      'expiry_year': method.expiryYear,
      'is_default': method.isDefault,
    });
  }

  Future<void> deletePaymentMethod(String id) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.delete('/payments/methods/$id/');
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.post('/payments/methods/$id/set-default/');
  }
}
