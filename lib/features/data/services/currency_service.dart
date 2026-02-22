import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';

class CurrencyService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getCurrencyData() async {
    try {
      final response = await _api.get('/currency/rates/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      print('Error getting currency data: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      if (fromCurrency == toCurrency) {
        return {
          'success': true,
          'data': {
            'originalAmount': amount,
            'convertedAmount': amount,
            'fromCurrency': fromCurrency,
            'toCurrency': toCurrency,
            'rate': 1.0,
          },
        };
      }

      final response = await _api.post('/currency/convert/', data: {
        'amount': amount,
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
      });

      return {'success': true, 'data': response.data};
    } catch (e) {
      print('Error converting amount: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> updateUserCurrencyPreference(String currency) async {
    try {
      if (!AuthService.isAuthenticated()) return;

      await _api.patch('/currency/preference/', data: {
        'preferred_currency': currency,
      });
    } catch (e) {
      print('Error updating user currency preference: $e');
    }
  }

  Future<String?> getUserCurrencyPreference() async {
    try {
      if (!AuthService.isAuthenticated()) return null;

      final response = await _api.get('/currency/preference/');
      return response.data?['preferred_currency'];
    } catch (e) {
      print('Error getting user currency preference: $e');
      return null;
    }
  }

  Future<double?> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      if (fromCurrency == toCurrency) return 1.0;

      final response = await _api.get(
        '/currency/rate/',
        queryParameters: {'from': fromCurrency, 'to': toCurrency},
      );

      if (response.data != null && response.data['rate'] != null) {
        return (response.data['rate'] as num).toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting exchange rate: $e');
      return null;
    }
  }

  Future<Map<String, Map<String, double>>> convertProductPrices(
    Map<String, double> prices,
    String fromCurrency,
    List<String> targetCurrencies,
  ) async {
    try {
      final Map<String, Map<String, double>> convertedPrices = {};

      for (final targetCurrency in targetCurrencies) {
        if (targetCurrency == fromCurrency) {
          convertedPrices[targetCurrency] = prices;
          continue;
        }

        final rate = await getExchangeRate(fromCurrency, targetCurrency);
        if (rate != null) {
          convertedPrices[targetCurrency] = {};
          prices.forEach((priceType, amount) {
            convertedPrices[targetCurrency]![priceType] =
                (amount * rate * 100).round() / 100;
          });
        }
      }

      return convertedPrices;
    } catch (e) {
      print('Error converting product prices: $e');
      rethrow;
    }
  }
}
