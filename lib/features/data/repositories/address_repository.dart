import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/address_model.dart';

class AddressRepository {
  final _api = ApiClient.instance;

  Future<List<Address>> getAddresses() async {
    if (!AuthService.isAuthenticated()) return [];

    final response = await _api.get('/shipping-addresses/');
    final results = ApiClient.unwrapResults(response.data);
    return results
        .map((json) => Address.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> addAddress(Address address) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    final response = await _api.post(
      '/shipping-addresses/',
      data: {
        'name': address.name,
        'phone': address.phone,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'zip': address.zip,
        'country': address.country,
        'is_default': address.isDefault,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['id'].toString();
  }

  Future<void> updateAddress(Address address) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.patch(
      '/shipping-addresses/${address.id}/',
      data: {
        'name': address.name,
        'phone': address.phone,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'zip': address.zip,
        'country': address.country,
        'is_default': address.isDefault,
      },
    );
  }

  Future<void> deleteAddress(String id) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.delete('/shipping-addresses/$id/');
  }

  Future<void> setDefaultAddress(String id) async {
    if (!AuthService.isAuthenticated()) {
      throw Exception('User not authenticated');
    }

    await _api.post('/shipping-addresses/$id/set-default/');
  }
}
