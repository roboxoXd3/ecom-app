import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address_model.dart';
import '../../../core/services/auth_service.dart';

class AddressRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Address>> getAddresses() async {
    final userId = AuthService.getCurrentUserId();

    final response = await _supabase
        .from('shipping_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return (response as List).map((json) => Address.fromJson(json)).toList();
  }

  Future<String> addAddress(Address address) async {
    final userId = AuthService.getCurrentUserId();

    // If this is the first address, make it default
    final addresses = await getAddresses();
    final isFirst = addresses.isEmpty;
    final shouldBeDefault = isFirst || address.isDefault;

    // If this should be default, first set all existing addresses to non-default
    if (shouldBeDefault && addresses.isNotEmpty) {
      await _supabase
          .from('shipping_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    // Insert the new address and return the created record
    final response =
        await _supabase
            .from('shipping_addresses')
            .insert({
              'user_id': userId,
              'name': address.name,
              'phone': address.phone,
              'address_line1': address.addressLine1,
              'address_line2': address.addressLine2,
              'city': address.city,
              'state': address.state,
              'zip': address.zip,
              'country': address.country,
              'is_default': shouldBeDefault,
            })
            .select()
            .single();

    // Return the ID of the newly created address
    return response['id'].toString();
  }

  Future<void> updateAddress(Address address) async {
    final userId = AuthService.getCurrentUserId();

    await _supabase
        .from('shipping_addresses')
        .update({
          'name': address.name,
          'phone': address.phone,
          'address_line1': address.addressLine1,
          'address_line2': address.addressLine2,
          'city': address.city,
          'state': address.state,
          'zip': address.zip,
          'country': address.country,
          'is_default': address.isDefault,
        })
        .eq('id', address.id)
        .eq(
          'user_id',
          userId,
        ); // Ensure user can only update their own addresses

    if (address.isDefault) {
      await _supabase
          .from('shipping_addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .neq('id', address.id);
    }
  }

  Future<void> deleteAddress(String id) async {
    final userId = AuthService.getCurrentUserId();

    // Get the address to check if it was default
    final address =
        await _supabase
            .from('shipping_addresses')
            .select()
            .eq('id', id)
            .eq('user_id', userId)
            .single();

    await _supabase
        .from('shipping_addresses')
        .delete()
        .eq('id', id)
        .eq(
          'user_id',
          userId,
        ); // Ensure user can only delete their own addresses

    // If deleted address was default, make the first remaining address default
    if (address['is_default']) {
      final remaining = await getAddresses();
      if (remaining.isNotEmpty) {
        await setDefaultAddress(remaining.first.id);
      }
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final userId = AuthService.getCurrentUserId();

    // First, set all user's addresses to non-default
    await _supabase
        .from('shipping_addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .not('id', 'eq', id);

    // Then set the selected address as default
    await _supabase
        .from('shipping_addresses')
        .update({'is_default': true})
        .eq('id', id)
        .eq(
          'user_id',
          userId,
        ); // Ensure user can only set their own addresses as default
  }
}
