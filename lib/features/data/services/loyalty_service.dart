import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  final _api = ApiClient.instance;

  Future<LoyaltyAccount?> getLoyaltyBalance() async {
    try {
      if (!AuthService.isAuthenticated()) return null;

      final response = await _api.get('/loyalty/points/');
      final data = response.data;

      if (data == null || (data is Map && data.isEmpty)) {
        return LoyaltyAccount(
          id: '',
          userId: AuthService.getCurrentUserId(),
          pointsBalance: 0,
          lifetimePoints: 0,
          tier: 'bronze',
          tierUpdatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tierMultiplier: 1.0,
          tierProgress: 0.0,
          nextTier: 'silver',
          pointsToNextTier: 500,
        );
      }

      return LoyaltyAccount.fromJson(data);
    } catch (e) {
      print('Error fetching loyalty balance: $e');
      return null;
    }
  }

  Future<List<LoyaltyTransaction>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
    String? type,
  }) async {
    try {
      if (!AuthService.isAuthenticated()) return [];

      final params = <String, dynamic>{
        'page_size': limit,
        'page': (offset ~/ limit) + 1,
      };
      if (type != null) params['type'] = type;

      final response = await _api.get('/loyalty/transactions/', queryParameters: params);
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => LoyaltyTransaction.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching transaction history: $e');
      return [];
    }
  }

  Future<List<LoyaltyReward>> getAvailableRewards() async {
    try {
      final response = await _api.get('/loyalty/rewards/');
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => LoyaltyReward.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching rewards: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      if (!AuthService.isAuthenticated()) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final response = await _api.post(
        '/loyalty/redeem/',
        data: {'reward_id': rewardId},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        data['success'] = true;
        return data;
      }

      return {'success': false, 'error': 'Unexpected response'};
    } catch (e) {
      print('Error redeeming reward: $e');
      final errMsg = e.toString().contains('Insufficient')
          ? 'Insufficient points to redeem this reward'
          : 'An error occurred while redeeming';
      return {'success': false, 'error': errMsg};
    }
  }

  Future<List<LoyaltyVoucher>> getUserVouchers({String? status}) async {
    try {
      if (!AuthService.isAuthenticated()) return [];

      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;

      final response = await _api.get('/loyalty/vouchers/', queryParameters: params);
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => LoyaltyVoucher.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> validateVoucher(
    String voucherCode,
    double orderSubtotal,
  ) async {
    try {
      final response = await _api.post(
        '/loyalty/validate-voucher/',
        data: {
          'voucher_code': voucherCode,
          'order_subtotal': orderSubtotal,
        },
      );

      return response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : {'valid': false, 'error': 'Invalid response'};
    } catch (e) {
      print('Error validating voucher: $e');
      return {'valid': false, 'error': 'An error occurred while validating'};
    }
  }

  Future<List<LoyaltyBadge>> getUserBadges() async {
    try {
      if (!AuthService.isAuthenticated()) return [];

      final response = await _api.get('/loyalty/user-badges/');
      final data = response.data;
      final results = data is Map ? (data['results'] as List?) ?? [] : data as List;
      return results.map((json) => LoyaltyBadge.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getBadgeProgress() async {
    try {
      if (!AuthService.isAuthenticated()) return {};

      final response = await _api.get('/loyalty/badge-progress/');
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {};
    } catch (e) {
      print('Error fetching badge progress: $e');
      return {};
    }
  }

  Future<void> refreshLoyaltyData() async {
    await getLoyaltyBalance();
  }
}
