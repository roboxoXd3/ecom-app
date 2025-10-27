import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's loyalty balance and tier info
  Future<LoyaltyAccount?> getLoyaltyBalance() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Query loyalty_points table directly
      final data =
          await _supabase
              .from('loyalty_points')
              .select('*')
              .eq('user_id', user.id)
              .maybeSingle();

      if (data == null) {
        // No loyalty account yet - return default account
        // The database trigger will create it on first order
        return LoyaltyAccount(
          id: '',
          userId: user.id,
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

      // Calculate tier progress and next tier
      final tierThresholds = {
        'bronze': 0,
        'silver': 500,
        'gold': 2000,
        'platinum': 5000,
      };

      final lifetimePoints = data['lifetime_points'] ?? 0;
      String currentTier = data['tier'] ?? 'bronze';
      String? nextTier;
      double progress = 0.0;
      int pointsToNext = 0;

      // Determine next tier and progress
      if (currentTier == 'bronze') {
        nextTier = 'silver';
        pointsToNext = (tierThresholds['silver']! - lifetimePoints).toInt();
        progress = (lifetimePoints / tierThresholds['silver']!) * 100;
      } else if (currentTier == 'silver') {
        nextTier = 'gold';
        final pointsInTier =
            (lifetimePoints - tierThresholds['silver']!).toInt();
        final tierRange =
            (tierThresholds['gold']! - tierThresholds['silver']!).toInt();
        pointsToNext = (tierThresholds['gold']! - lifetimePoints).toInt();
        progress = (pointsInTier / tierRange) * 100;
      } else if (currentTier == 'gold') {
        nextTier = 'platinum';
        final pointsInTier = (lifetimePoints - tierThresholds['gold']!).toInt();
        final tierRange =
            (tierThresholds['platinum']! - tierThresholds['gold']!).toInt();
        pointsToNext = (tierThresholds['platinum']! - lifetimePoints).toInt();
        progress = (pointsInTier / tierRange) * 100;
      } else if (currentTier == 'platinum') {
        nextTier = null;
        progress = 100.0;
        pointsToNext = 0;
      }

      return LoyaltyAccount.fromJson({
        ...data,
        'tier_progress': progress,
        'next_tier': nextTier,
        'points_to_next_tier': pointsToNext > 0 ? pointsToNext : 0,
      });
    } catch (e) {
      print('Error fetching loyalty balance: $e');
      return null;
    }
  }

  /// Get user's loyalty transaction history
  Future<List<LoyaltyTransaction>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
    String? type,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Query loyalty_transactions table directly
      var query = _supabase
          .from('loyalty_transactions')
          .select('*')
          .eq('user_id', user.id);

      // Apply type filter if provided
      if (type != null) {
        query = query.eq('transaction_type', type);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List)
          .map((json) => LoyaltyTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching transaction history: $e');
      return [];
    }
  }

  /// Get available rewards to redeem
  Future<List<LoyaltyReward>> getAvailableRewards() async {
    try {
      final user = _supabase.auth.currentUser;

      // Query loyalty_rewards table directly
      final data = await _supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('is_active', true)
          .order('points_required', ascending: true);

      // Get user's current points balance
      int userPoints = 0;
      if (user != null) {
        final loyaltyData =
            await _supabase
                .from('loyalty_points')
                .select('points_balance')
                .eq('user_id', user.id)
                .maybeSingle();

        userPoints = loyaltyData?['points_balance'] ?? 0;
      }

      // Get user's redemption counts for each reward
      Map<String, int> redemptionCounts = {};
      if (user != null) {
        final vouchers = await _supabase
            .from('loyalty_vouchers')
            .select('reward_id')
            .eq('user_id', user.id);

        for (var voucher in vouchers as List) {
          final rewardId = voucher['reward_id'];
          redemptionCounts[rewardId] = (redemptionCounts[rewardId] ?? 0) + 1;
        }
      }

      return (data as List).map((json) {
        final pointsRequired = json['points_required'] ?? 0;
        final canRedeem = userPoints >= pointsRequired;
        final maxRedemptions = json['max_redemptions_per_user'];
        final userRedemptions = redemptionCounts[json['id']] ?? 0;
        final canRedeemMore =
            maxRedemptions == null || userRedemptions < maxRedemptions;

        return LoyaltyReward.fromJson({
          ...json,
          'can_redeem': canRedeem,
          'user_redemption_count': userRedemptions,
          'can_redeem_more': canRedeemMore,
        });
      }).toList();
    } catch (e) {
      print('Error fetching rewards: $e');
      return [];
    }
  }

  /// Redeem a reward for a voucher
  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Get reward details first to know points required
      final rewardData =
          await _supabase
              .from('loyalty_rewards')
              .select('points_required, name')
              .eq('id', rewardId)
              .single();

      final pointsRequired = rewardData['points_required'] as int;

      // Call the correct Supabase RPC function (same as website)
      // This function returns a voucher code string or error string
      final voucherCode = await _supabase.rpc(
        'redeem_loyalty_points',
        params: {
          'user_uuid': user.id,
          'points_to_redeem': pointsRequired,
          'reward_id_param': rewardId,
          'order_id_param': null,
        },
      );

      // Check for error responses (returned as strings)
      if (voucherCode == 'INSUFFICIENT_POINTS') {
        return {'success': false, 'error': 'Insufficient points'};
      }

      if (voucherCode == 'REWARD_NOT_FOUND') {
        return {'success': false, 'error': 'Reward not found or inactive'};
      }

      // Success - voucherCode is the actual voucher code string
      return {
        'success': true,
        'voucher': {
          'voucher_code': voucherCode,
          'points_spent': pointsRequired,
          'reward_name': rewardData['name'],
        },
        'new_balance': null, // Will be refetched by refreshBalance()
      };
    } catch (e) {
      print('Error redeeming reward: $e');
      return {'success': false, 'error': 'An error occurred while redeeming'};
    }
  }

  /// Get user's vouchers
  Future<List<LoyaltyVoucher>> getUserVouchers({String? status}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Query loyalty_vouchers table with join to loyalty_rewards
      var query = _supabase
          .from('loyalty_vouchers')
          .select('*, reward:loyalty_rewards(*)')
          .eq('user_id', user.id);

      // Apply status filter if provided
      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('created_at', ascending: false);

      return (data as List).map((json) {
        // Check if expired
        final expiresAt = DateTime.parse(json['expires_at']);
        final isExpired = expiresAt.isBefore(DateTime.now());

        // Extract reward info from joined data
        final reward = json['reward'];
        final rewardName = reward?['name'] ?? '';
        final rewardDescription = reward?['description'];

        return LoyaltyVoucher.fromJson({
          ...json,
          'reward_name': rewardName,
          'reward_description': rewardDescription,
          'is_expired': isExpired,
        });
      }).toList();
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  /// Validate voucher code
  Future<Map<String, dynamic>> validateVoucher(
    String voucherCode,
    double orderSubtotal,
  ) async {
    try {
      // Call Supabase RPC function to validate voucher
      final data = await _supabase.rpc(
        'validate_loyalty_voucher',
        params: {
          'p_voucher_code': voucherCode,
          'p_order_subtotal': orderSubtotal,
        },
      );

      if (data != null && data['valid'] == true) {
        return {
          'valid': true,
          'voucher_id': data['voucher_id'],
          'voucher_code': data['voucher_code'],
          'discount_type': data['discount_type'],
          'discount_amount': data['discount_amount'],
          'apply_to_shipping': data['apply_to_shipping'] ?? false,
        };
      } else {
        return {'valid': false, 'error': data?['error'] ?? 'Invalid voucher'};
      }
    } catch (e) {
      print('Error validating voucher: $e');
      return {'valid': false, 'error': 'An error occurred while validating'};
    }
  }

  /// Get user's badges
  Future<List<LoyaltyBadge>> getUserBadges() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get all available badges
      final allBadges = await _supabase
          .from('loyalty_badges')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      // Get user's earned badges
      final userBadges = await _supabase
          .from('user_badges')
          .select('badge_id, earned_at')
          .eq('user_id', user.id);

      // Create a set of earned badge IDs for quick lookup
      final earnedBadgeIds =
          (userBadges as List).map((ub) => ub['badge_id'] as String).toSet();

      // Get user stats for progress calculation
      final ordersData = await _supabase
          .from('orders')
          .select('id, total')
          .eq('user_id', user.id)
          .eq('status', 'delivered');

      final totalOrders = (ordersData as List).length;

      double totalSpending = 0;
      for (var order in ordersData) {
        totalSpending += (order['total'] ?? 0).toDouble();
      }

      // Merge the data
      final badges =
          (allBadges as List).map((badge) {
            final badgeId = badge['id'] as String;
            final isEarned = earnedBadgeIds.contains(badgeId);

            // Find the earned date if badge is earned
            Map<String, dynamic>? userBadge;
            try {
              userBadge = (userBadges as List)
                  .cast<Map<String, dynamic>>()
                  .firstWhere((ub) => ub['badge_id'] == badgeId);
            } catch (e) {
              // Badge not found in user's earned badges - this is fine
              userBadge = null;
            }

            // Calculate progress based on badge type
            double progress = 0.0;
            int currentValue = 0;
            final requirementValue = badge['requirement_value'];

            if (!isEarned && requirementValue != null) {
              final badgeType = badge['badge_type'];

              if (badgeType == 'order_count') {
                currentValue = totalOrders;
                progress = (totalOrders / requirementValue) * 100;
              } else if (badgeType == 'spending_amount') {
                currentValue = totalSpending.toInt();
                progress = (totalSpending / requirementValue) * 100;
              }

              // Cap progress at 100%
              if (progress > 100) progress = 100;
            } else if (isEarned) {
              progress = 100.0;
            }

            return LoyaltyBadge.fromJson({
              ...badge,
              'is_earned': isEarned,
              'earned_at': userBadge?['earned_at'],
              'progress': progress,
              'current_value': currentValue,
            });
          }).toList();

      // Sort: earned badges first, then by progress
      badges.sort((a, b) {
        if (a.isEarned && !b.isEarned) return -1;
        if (!a.isEarned && b.isEarned) return 1;
        if (!a.isEarned && !b.isEarned) {
          return b.progress.compareTo(a.progress);
        }
        return a.displayOrder.compareTo(b.displayOrder);
      });

      return badges;
    } catch (e) {
      print('Error fetching badges: $e');
      return [];
    }
  }

  /// Refresh loyalty data (call after order completion)
  Future<void> refreshLoyaltyData() async {
    // This will trigger a re-fetch of loyalty data
    // Can be called from controllers after order completion
    await getLoyaltyBalance();
  }
}
