import 'package:get/get.dart';

import '../../data/models/address_model.dart';
import '../../data/repositories/address_repository.dart';

class AddressController extends GetxController {
  final AddressRepository _addressRepository = AddressRepository();
  final RxList<Address> addresses = <Address>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(addresses, (_) => update());
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final fetchedAddresses = await _addressRepository.getAddresses();
      addresses.assignAll(fetchedAddresses);
    } catch (e) {
      print('Error fetching addresses: $e');
      Get.snackbar(
        'Error',
        'Failed to load addresses',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAddress({
    required String name,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zip,
    required String country,
    required bool isDefault,
  }) async {
    try {
      isLoading.value = true;
      final address = Address(
        id: '',
        userId: '',
        name: name,
        phone: phone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        zip: zip,
        country: country,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      await _addressRepository.addAddress(address);
      await fetchAddresses();
      Get.back();
      Get.snackbar(
        'Success',
        'Address added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error adding address: $e');
      Get.snackbar(
        'Error',
        'Failed to add address: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      isLoading.value = true;
      await _addressRepository.updateAddress(address);
      await fetchAddresses();
      Get.back();
      Get.snackbar(
        'Success',
        'Address updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating address: $e');
      Get.snackbar(
        'Error',
        'Failed to update address',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _addressRepository.deleteAddress(id);
      await fetchAddresses();
      Get.snackbar('Success', 'Address deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete address');
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      await _addressRepository.setDefaultAddress(id);
      await fetchAddresses();
      Get.snackbar('Success', 'Default address updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update default address');
    }
  }
}
