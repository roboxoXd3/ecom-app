import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/features/data/services/currency_service.dart';
import '../helpers/mock_api_client.dart';

void main() {
  late CurrencyService service;
  late MockDioHelper mockDio;

  setUp(() {
    mockDio = MockDioHelper();
    service = CurrencyService();
  });

  group('getCurrencyData', () {
    test('returns success with currency data', () async {
      mockDio.addGetResponse('/currency/rates/', {
        'supported_currencies': ['NGN', 'USD', 'GBP'],
        'default_currency': {'code': 'NGN', 'symbol': '₦'},
        'exchange_rates': {
          'USD': {'NGN': 1500.0},
        },
      });
      mockDio.install();

      final result = await service.getCurrencyData();

      expect(result['success'], isTrue);
      expect(result['data'], isNotNull);
    });

    test('returns error on failure', () async {
      mockDio.addErrorResponse('/currency/rates/', 500, {'error': 'fail'});
      mockDio.install();

      final result = await service.getCurrencyData();

      expect(result['success'], isFalse);
    });
  });

  group('convertAmount', () {
    test('returns same amount for same currency', () async {
      mockDio.install();

      final result = await service.convertAmount(100.0, 'NGN', 'NGN');

      expect(result['success'], isTrue);
      expect(result['data']['convertedAmount'], 100.0);
      expect(result['data']['rate'], 1.0);
    });

    test('calls API for different currencies', () async {
      mockDio.addPostResponse('/currency/convert/', {
        'original_amount': 100.0,
        'converted_amount': 150000.0,
        'from_currency': 'USD',
        'to_currency': 'NGN',
        'rate': 1500.0,
      });
      mockDio.install();

      final result = await service.convertAmount(100.0, 'USD', 'NGN');

      expect(result['success'], isTrue);
    });
  });

  group('getExchangeRate', () {
    test('returns 1.0 for same currency', () async {
      mockDio.install();

      final rate = await service.getExchangeRate('NGN', 'NGN');
      expect(rate, 1.0);
    });

    test('returns rate from API', () async {
      mockDio.addGetResponse('/currency/rate/', {
        'from': 'USD',
        'to': 'NGN',
        'rate': 1500.0,
      });
      mockDio.install();

      final rate = await service.getExchangeRate('USD', 'NGN');
      expect(rate, 1500.0);
    });

    test('returns null on error', () async {
      mockDio.addErrorResponse('/currency/rate/', 404, {'error': 'not found'});
      mockDio.install();

      final rate = await service.getExchangeRate('USD', 'XYZ');
      expect(rate, isNull);
    });
  });
}
