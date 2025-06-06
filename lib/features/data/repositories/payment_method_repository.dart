import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PaymentMethod>> getPaymentMethods() async {
    // Get the current authenticated user's ID
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final userId = currentUser.id;
    print('Fetching payment methods for user: $userId');

    final response = await _supabase
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return (response as List)
        .map((json) => PaymentMethod.fromJson(json))
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
      print('Attempting to add payment method to Supabase...');
      print(
        'Data: userId=$userId, type=$type, displayName=$displayName, last4=$last4',
      );

      final response =
          await _supabase
              .from('payment_methods')
              .insert({
                'user_id':
                    userId, // This should be a UUID, but we'll keep as string for now
                'card_type':
                    cardBrand ?? type, // Using card_type instead of card_brand
                'card_holder_name':
                    displayName, // Using card_holder_name instead of display_name
                'card_number': last4, // Using card_number instead of last4
                'expiry_month': expiryMonth,
                'expiry_year': expiryYear,
                'is_default': false,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      print('Supabase response: $response');
      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('Error adding payment method to Supabase: $e');
      print('Error type: ${e.runtimeType}');
      rethrow; // Re-throw to let the controller handle it
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod method) async {
    await _supabase
        .from('payment_methods')
        .update({
          'card_type': method.type,
          'card_holder_name': method.displayName,
          'card_number': method.last4,
          'expiry_month': method.expiryMonth,
          'expiry_year': method.expiryYear,
          'is_default': method.isDefault,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', method.id);

    if (method.isDefault) {
      await _supabase
          .from('payment_methods')
          .update({'is_default': false})
          .neq('id', method.id);
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    // Get the current authenticated user's ID for security
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final userId = currentUser.id;

    final method =
        await _supabase
            .from('payment_methods')
            .select()
            .eq('id', id)
            .eq('user_id', userId) // Ensure it belongs to the current user
            .single();

    await _supabase
        .from('payment_methods')
        .delete()
        .eq('id', id)
        .eq('user_id', userId); // Ensure it belongs to the current user

    // If deleted card was default, make the first remaining card default
    if (method['is_default']) {
      final remaining = await getPaymentMethods();
      if (remaining.isNotEmpty) {
        await setDefaultPaymentMethod(remaining.first.id);
      }
    }
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    // Get the current authenticated user's ID for security
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final userId = currentUser.id;

    // First, set all user's cards to non-default
    await _supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);

    // Then set the selected card as default
    await _supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', id)
        .eq('user_id', userId); // Ensure it belongs to the current user
  }
}
