import 'package:get/get.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/repositories/payment_method_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';

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

      if (!AuthService.isAuthenticated()) {
        paymentMethods.clear();
        return;
      }

      paymentMethods.value = await _repository.getPaymentMethods();
    } catch (e) {
      print('Error fetching payment methods: $e');
      if (!SnackbarUtils.isNoInternet(e) && AuthService.isAuthenticated()) {
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

      final userId = AuthService.isAuthenticated() ? AuthService.getCurrentUserId() : null;
      if (userId == null) {
        Get.snackbar('Error', 'Please log in to add payment methods');
        return;
      }

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
        await fetchPaymentMethods();
        Get.snackbar('Success', 'Card added successfully');
      } else {
        Get.snackbar('Error', 'Failed to add card. Please try again.');
      }
    } catch (e) {
      print('Error adding payment method: $e');
      if (!SnackbarUtils.isNoInternet(e)) {
        Get.snackbar('Error', 'Failed to add card. Please try again.');
      }
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
      if (!SnackbarUtils.isNoInternet(e)) {
        Get.snackbar('Error', 'Failed to delete card');
      }
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
      if (!SnackbarUtils.isNoInternet(e)) {
        Get.snackbar('Error', 'Failed to update default card');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
