import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address_model.dart';

class AddressRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Address>> getAddresses() async {
    final response = await _supabase
        .from('shipping_addresses')
        .select()
        .order('is_default', ascending: false);

    return (response as List).map((json) => Address.fromJson(json)).toList();
  }

  Future<void> addAddress(Address address) async {
    // If this is the first address, make it default
    final addresses = await getAddresses();
    final isFirst = addresses.isEmpty;

    await _supabase.from('shipping_addresses').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'name': address.name,
      'phone': address.phone,
      'address_line1': address.addressLine1,
      'address_line2': address.addressLine2,
      'city': address.city,
      'state': address.state,
      'zip': address.zip,
      'country': address.country,
      'is_default': isFirst || address.isDefault,
    });

    // If setting as default, update other addresses
    if (address.isDefault) {
      await _supabase
          .from('shipping_addresses')
          .update({'is_default': false})
          .neq('id', address.id);
    }
  }

  Future<void> updateAddress(Address address) async {
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
        .eq('id', address.id);

    if (address.isDefault) {
      await _supabase
          .from('shipping_addresses')
          .update({'is_default': false})
          .neq('id', address.id);
    }
  }

  Future<void> deleteAddress(String id) async {
    final address =
        await _supabase
            .from('shipping_addresses')
            .select()
            .eq('id', id)
            .single();

    await _supabase.from('shipping_addresses').delete().eq('id', id);

    // If deleted address was default, make the first remaining address default
    if (address['is_default']) {
      final remaining = await getAddresses();
      if (remaining.isNotEmpty) {
        await setDefaultAddress(remaining.first.id);
      }
    }
  }

  Future<void> setDefaultAddress(String id) async {
    // First, set all addresses to non-default
    await _supabase
        .from('shipping_addresses')
        .update({'is_default': false})
        .not('id', 'eq', id);

    // Then set the selected address as default
    await _supabase
        .from('shipping_addresses')
        .update({'is_default': true})
        .eq('id', id);
  }
}
