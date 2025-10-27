import 'package:get/get.dart';
import '../../data/models/loyalty_model.dart';
import '../../data/services/loyalty_service.dart';

class LoyaltyController extends GetxController {
  final LoyaltyService _loyaltyService = LoyaltyService();

  // Observable data
  final Rx<LoyaltyAccount?> loyaltyAccount = Rx<LoyaltyAccount?>(null);
  final RxList<LoyaltyTransaction> transactions = <LoyaltyTransaction>[].obs;
  final RxList<LoyaltyReward> rewards = <LoyaltyReward>[].obs;
  final RxList<LoyaltyVoucher> vouchers = <LoyaltyVoucher>[].obs;
  final RxList<LoyaltyBadge> badges = <LoyaltyBadge>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isLoadingRewards = false.obs;
  final RxBool isLoadingVouchers = false.obs;
  final RxBool isLoadingBadges = false.obs;
  final RxString error = ''.obs;

  // Voucher code for checkout
  final RxString appliedVoucherCode = ''.obs;
  final RxDouble voucherDiscountAmount = 0.0.obs;
  final RxBool applyVoucherToShipping = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLoyaltyData();
  }

  /// Load all loyalty data
  Future<void> loadLoyaltyData() async {
    await refreshBalance();
    await loadRewards();
    await loadVouchers();
  }

  /// Refresh loyalty balance
  Future<void> refreshBalance() async {
    try {
      isLoading.value = true;
      error.value = '';

      final account = await _loyaltyService.getLoyaltyBalance();
      if (account != null) {
        loyaltyAccount.value = account;
      }
    } catch (e) {
      error.value = 'Failed to load loyalty balance';
      print('Error refreshing balance: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load transaction history
  Future<void> loadTransactionHistory({
    int limit = 50,
    int offset = 0,
    String? type,
  }) async {
    try {
      isLoadingTransactions.value = true;
      error.value = '';

      final txList = await _loyaltyService.getTransactionHistory(
        limit: limit,
        offset: offset,
        type: type,
      );

      if (offset == 0) {
        transactions.value = txList;
      } else {
        transactions.addAll(txList);
      }
    } catch (e) {
      error.value = 'Failed to load transactions';
      print('Error loading transactions: $e');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  /// Load available rewards
  Future<void> loadRewards() async {
    try {
      isLoadingRewards.value = true;
      error.value = '';

      final rewardsList = await _loyaltyService.getAvailableRewards();
      rewards.value = rewardsList;
    } catch (e) {
      error.value = 'Failed to load rewards';
      print('Error loading rewards: $e');
    } finally {
      isLoadingRewards.value = false;
    }
  }

  /// Redeem a reward
  Future<bool> redeemReward(String rewardId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await _loyaltyService.redeemReward(rewardId);

      if (result['success'] == true) {
        // Refresh data
        await refreshBalance();
        await loadVouchers();

        Get.snackbar(
          'Success',
          'Reward redeemed successfully! Check your vouchers.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );

        return true;
      } else {
        error.value = result['error'] ?? 'Failed to redeem reward';
        Get.snackbar(
          'Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred';
      print('Error redeeming reward: $e');
      Get.snackbar(
        'Error',
        'An error occurred while redeeming',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load user's vouchers
  Future<void> loadVouchers({String? status}) async {
    try {
      isLoadingVouchers.value = true;
      error.value = '';

      final vouchersList = await _loyaltyService.getUserVouchers(
        status: status,
      );
      vouchers.value = vouchersList;
    } catch (e) {
      error.value = 'Failed to load vouchers';
      print('Error loading vouchers: $e');
    } finally {
      isLoadingVouchers.value = false;
    }
  }

  /// Get vouchers by status
  List<LoyaltyVoucher> getVouchersByStatus(String status) {
    return vouchers.where((v) => v.status == status).toList();
  }

  /// Validate and apply voucher at checkout
  Future<bool> validateAndApplyVoucher(
    String voucherCode,
    double orderSubtotal,
  ) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await _loyaltyService.validateVoucher(
        voucherCode,
        orderSubtotal,
      );

      if (result['valid'] == true) {
        appliedVoucherCode.value = voucherCode;
        voucherDiscountAmount.value = result['discount_amount'] ?? 0.0;
        applyVoucherToShipping.value = result['apply_to_shipping'] ?? false;

        Get.snackbar(
          'Success',
          'Voucher applied successfully!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        return true;
      } else {
        error.value = result['error'] ?? 'Invalid voucher';
        Get.snackbar(
          'Error',
          error.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred';
      print('Error validating voucher: $e');
      Get.snackbar(
        'Error',
        'An error occurred while validating voucher',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove applied voucher
  void removeVoucher() {
    appliedVoucherCode.value = '';
    voucherDiscountAmount.value = 0.0;
    applyVoucherToShipping.value = false;
  }

  /// Load user's badges
  Future<void> loadBadges() async {
    try {
      isLoadingBadges.value = true;
      error.value = '';

      final badgesList = await _loyaltyService.getUserBadges();
      badges.value = badgesList;
    } catch (e) {
      error.value = 'Failed to load badges';
      print('Error loading badges: $e');
    } finally {
      isLoadingBadges.value = false;
    }
  }

  /// Get earned badges
  List<LoyaltyBadge> get earnedBadges {
    return badges.where((b) => b.isEarned).toList();
  }

  /// Get available (not yet earned) badges
  List<LoyaltyBadge> get availableBadges {
    return badges.where((b) => !b.isEarned).toList();
  }

  /// Check if user can afford a reward
  bool canAffordReward(int pointsRequired) {
    return (loyaltyAccount.value?.pointsBalance ?? 0) >= pointsRequired;
  }

  /// Get tier color
  String getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#CD7F32';
    }
  }

  /// Format points with thousands separator
  String formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}
