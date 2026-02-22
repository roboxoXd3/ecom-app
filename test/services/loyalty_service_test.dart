import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/services/loyalty_service.dart';
import '../helpers/mock_api_client.dart';

void main() {
  late LoyaltyService service;
  late MockDioHelper mockDio;

  setUp(() {
    mockDio = MockDioHelper();
    service = LoyaltyService();
  });

  group('getAvailableRewards', () {
    test('returns list of rewards from paginated response', () async {
      mockDio.addGetResponse('/loyalty/rewards/', {
        'count': 2,
        'results': [
          {
            'id': 'reward-1',
            'name': '10% Off Coupon',
            'description': 'Get 10% off your next order',
            'points_required': 500,
            'reward_type': 'discount',
            'discount_value': 10,
            'is_active': true,
            'created_at': '2026-01-01T00:00:00.000Z',
            'updated_at': '2026-01-01T00:00:00.000Z',
          },
          {
            'id': 'reward-2',
            'name': 'Free Shipping',
            'description': 'Free shipping on your next order',
            'points_required': 200,
            'reward_type': 'shipping',
            'discount_value': 0,
            'is_active': true,
            'created_at': '2026-01-01T00:00:00.000Z',
            'updated_at': '2026-01-01T00:00:00.000Z',
          },
        ],
      });
      mockDio.install();

      final rewards = await service.getAvailableRewards();

      expect(rewards, hasLength(2));
      expect(rewards[0].name, '10% Off Coupon');
      expect(rewards[1].name, 'Free Shipping');
    });

    test('returns empty list on error', () async {
      mockDio.addErrorResponse('/loyalty/rewards/', 500, {'error': 'fail'});
      mockDio.install();

      final rewards = await service.getAvailableRewards();
      expect(rewards, isEmpty);
    });
  });

  group('validateVoucher', () {
    test('returns valid result for correct voucher', () async {
      mockDio.addPostResponse('/loyalty/validate-voucher/', {
        'valid': true,
        'voucher_id': 'v-1',
        'voucher_code': 'SAVE10',
        'discount_type': 'percentage',
        'discount_amount': 10,
      });
      mockDio.install();

      final result = await service.validateVoucher('SAVE10', 5000.0);

      expect(result['valid'], isTrue);
      expect(result['discount_amount'], 10);
    });

    test('returns invalid for bad voucher', () async {
      mockDio.addPostResponse('/loyalty/validate-voucher/', {
        'valid': false,
        'error': 'Voucher expired',
      });
      mockDio.install();

      final result = await service.validateVoucher('EXPIRED', 5000.0);

      expect(result['valid'], isFalse);
      expect(result['error'], 'Voucher expired');
    });
  });

  group('redeemReward', () {
    test('returns error on network failure', () async {
      mockDio.addErrorResponse('/loyalty/redeem/', 500, {'error': 'fail'}, method: 'POST');
      mockDio.install();

      final result = await service.redeemReward('reward-1');

      expect(result['success'], isFalse);
    });
  });
}
