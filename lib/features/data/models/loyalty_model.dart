// Loyalty Account Model
class LoyaltyAccount {
  final String id;
  final String userId;
  final int pointsBalance;
  final int lifetimePoints;
  final String tier;
  final DateTime tierUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double tierMultiplier;
  final double tierProgress;
  final String? nextTier;
  final int pointsToNextTier;

  LoyaltyAccount({
    required this.id,
    required this.userId,
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.tier,
    required this.tierUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.tierMultiplier = 1.0,
    this.tierProgress = 0.0,
    this.nextTier,
    this.pointsToNextTier = 0,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['user'] ?? '').toString(),
      pointsBalance: json['points_balance'] ?? 0,
      lifetimePoints: json['lifetime_points'] ?? 0,
      tier: json['tier'] ?? 'bronze',
      tierUpdatedAt: json['tier_updated_at'] != null
          ? DateTime.parse(json['tier_updated_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      tierMultiplier: (json['tier_multiplier'] ?? 1.0).toDouble(),
      tierProgress: (json['tier_progress'] ?? 0.0).toDouble(),
      nextTier: json['next_tier'],
      pointsToNextTier: json['points_to_next_tier'] ?? 0,
    );
  }

  String get tierDisplayName {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return 'Bronze';
    }
  }

  String get tierBenefits {
    switch (tier) {
      case 'bronze':
        return '1x points on purchases';
      case 'silver':
        return '1.25x points on purchases + exclusive rewards';
      case 'gold':
        return '1.5x points on purchases + gold rewards';
      case 'platinum':
        return '2x points on purchases + premium perks';
      default:
        return '1x points on purchases';
    }
  }
}

// Loyalty Transaction Model
class LoyaltyTransaction {
  final String id;
  final String userId;
  final int pointsChange;
  final String transactionType;
  final String? referenceType;
  final String? referenceId;
  final String description;
  final int pointsBalanceAfter;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.pointsChange,
    required this.transactionType,
    this.referenceType,
    this.referenceId,
    required this.description,
    required this.pointsBalanceAfter,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'],
      userId: json['user_id'],
      pointsChange: json['points_change'] ?? 0,
      transactionType: json['transaction_type'] ?? '',
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      description: json['description'] ?? '',
      pointsBalanceAfter: json['points_balance_after'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isPositive => pointsChange > 0;

  String get typeDisplayName {
    switch (transactionType) {
      case 'earn':
        return 'Earned';
      case 'redeem':
        return 'Redeemed';
      case 'bonus':
        return 'Bonus';
      case 'adjustment':
        return 'Adjustment';
      case 'expire':
        return 'Expired';
      default:
        return 'Transaction';
    }
  }
}

// Loyalty Reward Model
class LoyaltyReward {
  final String id;
  final String name;
  final String? description;
  final int pointsRequired;
  final String rewardType;
  final double? discountPercentage;
  final double? discountAmount;
  final double minimumOrderAmount;
  final int validityDays;
  final int? maxRedemptionsPerUser;
  final bool isActive;
  final int displayOrder;
  final bool canRedeem;
  final int userRedemptionCount;
  final bool canRedeemMore;

  LoyaltyReward({
    required this.id,
    required this.name,
    this.description,
    required this.pointsRequired,
    required this.rewardType,
    this.discountPercentage,
    this.discountAmount,
    this.minimumOrderAmount = 0,
    this.validityDays = 30,
    this.maxRedemptionsPerUser,
    this.isActive = true,
    this.displayOrder = 0,
    this.canRedeem = false,
    this.userRedemptionCount = 0,
    this.canRedeemMore = true,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      pointsRequired: json['points_required'] ?? 0,
      rewardType: json['reward_type'] ?? '',
      discountPercentage: json['discount_percentage']?.toDouble(),
      discountAmount: json['discount_amount']?.toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] ?? 0).toDouble(),
      validityDays: json['validity_days'] ?? 30,
      maxRedemptionsPerUser: json['max_redemptions_per_user'],
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      canRedeem: json['can_redeem'] ?? false,
      userRedemptionCount: json['user_redemption_count'] ?? 0,
      canRedeemMore: json['can_redeem_more'] ?? true,
    );
  }

  String get rewardTypeDisplayName {
    switch (rewardType) {
      case 'discount_percentage':
        return '${discountPercentage?.toStringAsFixed(0)}% Off';
      case 'discount_fixed':
        return '\$${discountAmount?.toStringAsFixed(2)} Off';
      case 'free_shipping':
        return 'Free Shipping';
      default:
        return 'Reward';
    }
  }

  String get rewardValue {
    switch (rewardType) {
      case 'discount_percentage':
        return '${discountPercentage?.toStringAsFixed(0)}% discount';
      case 'discount_fixed':
        return '\$${discountAmount?.toStringAsFixed(2)} off';
      case 'free_shipping':
        return 'Free shipping on your order';
      default:
        return 'Special reward';
    }
  }
}

// Loyalty Voucher Model
class LoyaltyVoucher {
  final String id;
  final String userId;
  final String rewardId;
  final String voucherCode;
  final int pointsSpent;
  final String discountType;
  final double discountValue;
  final double minimumOrderAmount;
  final String status;
  final DateTime redeemedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? orderId;
  final String rewardName;
  final String? rewardDescription;
  final bool isExpired;

  LoyaltyVoucher({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.voucherCode,
    required this.pointsSpent,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount = 0,
    required this.status,
    required this.redeemedAt,
    required this.expiresAt,
    this.usedAt,
    this.orderId,
    this.rewardName = '',
    this.rewardDescription,
    this.isExpired = false,
  });

  factory LoyaltyVoucher.fromJson(Map<String, dynamic> json) {
    return LoyaltyVoucher(
      id: json['id'],
      userId: json['user_id'],
      rewardId: json['reward_id'],
      voucherCode: json['voucher_code'] ?? '',
      pointsSpent: json['points_spent'] ?? 0,
      discountType: json['discount_type'] ?? '',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      redeemedAt: DateTime.parse(json['redeemed_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      orderId: json['order_id'],
      rewardName: json['reward_name'] ?? '',
      rewardDescription: json['reward_description'],
      isExpired: json['is_expired'] ?? false,
    );
  }

  bool get isActive => status == 'active' && !isExpired;
  bool get isUsed => status == 'used';

  String get statusDisplayName {
    if (isUsed) return 'Used';
    if (isExpired || status == 'expired') return 'Expired';
    return 'Active';
  }

  String get discountDisplayValue {
    switch (discountType) {
      case 'discount_percentage':
        return '${discountValue.toStringAsFixed(0)}% Off';
      case 'discount_fixed':
        return '\$${discountValue.toStringAsFixed(2)} Off';
      case 'free_shipping':
        return 'Free Shipping';
      default:
        return 'Discount';
    }
  }

  int get daysUntilExpiry {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }
}

// Loyalty Badge Model
class LoyaltyBadge {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String badgeType;
  final int? requirementValue;
  final int bonusPoints;
  final int displayOrder;
  final bool isActive;
  final bool isEarned;
  final DateTime? earnedAt;
  final double progress;
  final int currentValue;

  LoyaltyBadge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.badgeType,
    this.requirementValue,
    this.bonusPoints = 0,
    this.displayOrder = 0,
    this.isActive = true,
    this.isEarned = false,
    this.earnedAt,
    this.progress = 0.0,
    this.currentValue = 0,
  });

  factory LoyaltyBadge.fromJson(Map<String, dynamic> json) {
    return LoyaltyBadge(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url'],
      badgeType: json['badge_type'] ?? '',
      requirementValue: json['requirement_value'],
      bonusPoints: json['bonus_points'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      isEarned: json['is_earned'] ?? false,
      earnedAt:
          json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
      progress: (json['progress'] ?? 0.0).toDouble(),
      currentValue: json['current_value'] ?? 0,
    );
  }

  String get badgeTypeDisplayName {
    switch (badgeType) {
      case 'order_count':
        return 'Complete Orders';
      case 'spending_amount':
        return 'Total Spending';
      case 'streak':
        return 'Streak';
      case 'special':
        return 'Special Achievement';
      default:
        return 'Badge';
    }
  }

  String get requirementDisplayText {
    if (requirementValue == null) return '';

    switch (badgeType) {
      case 'order_count':
        return 'Complete $requirementValue orders';
      case 'spending_amount':
        return 'Spend \$$requirementValue';
      default:
        return '';
    }
  }

  String get progressDisplayText {
    if (isEarned) return 'Completed';
    if (requirementValue == null) return '';

    switch (badgeType) {
      case 'order_count':
        return '$currentValue / $requirementValue orders';
      case 'spending_amount':
        return '\$$currentValue / \$$requirementValue';
      default:
        return '${progress.toStringAsFixed(0)}%';
    }
  }
}
