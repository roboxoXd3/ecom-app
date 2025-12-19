import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/repositories/payment_method_repository.dart';

class PaymentMethodController extends GetxController {
  final PaymentMethodRepository _repository = PaymentMethodRepository();
  final RxList<PaymentMethod> paymentMethods = <PaymentMethod>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPaymentMethods();
  }

  Future<void> fetchPaymentMethods() async {
    try {
      isLoading.value = true;
      
      // Check if user is authenticated before fetching
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        print('User not authenticated, skipping payment methods fetch');
        paymentMethods.clear();
        return;
      }
      
      paymentMethods.value = await _repository.getPaymentMethods();
    } catch (e) {
      print('Error fetching payment methods: $e');
      // Only show error snackbar if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        Get.snackbar('Error', 'Failed to load payment methods');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPaymentMethod({
    required String type,
    required String displayName,
    String? last4,
    String? cardBrand,
    String? expiryMonth,
    String? expiryYear,
  }) async {
    try {
      isLoading.value = true;
      print('Adding payment method: $displayName');

      // Get the current authenticated user's ID
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'Please log in to add payment methods');
        return;
      }

      final userId = currentUser.id;
      print('Using authenticated user ID: $userId');

      final result = await _repository.addPaymentMethod(
        userId: userId,
        type: type,
        displayName: displayName,
        last4: last4,
        cardBrand: cardBrand,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

      if (result != null) {
        print('Payment method added successfully: ${result.id}');
        await fetchPaymentMethods(); // Refresh the list
        Get.snackbar('Success', 'Card added successfully');
      } else {
        print('Failed to add payment method - result is null');
        Get.snackbar('Error', 'Failed to add card. Please try again.');
      }
    } catch (e) {
      print('Error adding payment method: $e');
      Get.snackbar('Error', 'Failed to add card: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      isLoading.value = true;
      await _repository.deletePaymentMethod(id);
      await fetchPaymentMethods();
      Get.snackbar('Success', 'Card deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete card');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    try {
      isLoading.value = true;
      await _repository.setDefaultPaymentMethod(id);
      await fetchPaymentMethods();
      Get.snackbar('Success', 'Default card updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update default card');
    } finally {
      isLoading.value = false;
    }
  }
}
