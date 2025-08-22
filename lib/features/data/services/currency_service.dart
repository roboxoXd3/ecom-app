import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrencyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Base URL for currency API (configure this based on your environment)
  static const String _baseUrl =
      'https://your-vendor-dashboard-url.com'; // Update this

  // Get currency data from backend
  Future<Map<String, dynamic>> getCurrencyData() async {
    try {
      // First try to get from Supabase directly
      final response = await _getCurrencyDataFromSupabase();
      if (response['success'] == true) {
        return response;
      }

      // Fallback to API endpoint if available
      return await _getCurrencyDataFromAPI();
    } catch (e) {
      print('Error getting currency data: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get currency data directly from Supabase
  Future<Map<String, dynamic>> _getCurrencyDataFromSupabase() async {
    try {
      // Get app settings
      final settingsResponse = await _supabase
          .from('app_settings')
          .select('setting_key, setting_value')
          .inFilter('setting_key', [
            'supported_currencies',
            'default_currency',
          ]);

      if (settingsResponse.isEmpty) {
        throw Exception('No currency settings found');
      }

      // Get exchange rates
      final ratesResponse = await _supabase
          .from('currency_rates')
          .select('from_currency, to_currency, rate, updated_at')
          .order('updated_at', ascending: false);

      // Process settings
      List<dynamic> supportedCurrencies = [];
      Map<String, dynamic> defaultCurrency = {};

      for (final setting in settingsResponse) {
        if (setting['setting_key'] == 'supported_currencies') {
          supportedCurrencies = setting['setting_value'];
        } else if (setting['setting_key'] == 'default_currency') {
          defaultCurrency = setting['setting_value'];
        }
      }

      // Process rates
      final Map<String, dynamic> ratesMap = {};
      for (final rate in ratesResponse) {
        final fromCurrency = rate['from_currency'];
        if (ratesMap[fromCurrency] == null) {
          ratesMap[fromCurrency] = {};
        }
        ratesMap[fromCurrency][rate['to_currency']] = {
          'rate': rate['rate'],
          'updated_at': rate['updated_at'],
        };
      }

      return {
        'success': true,
        'data': {
          'supportedCurrencies': supportedCurrencies,
          'defaultCurrency': defaultCurrency,
          'exchangeRates': ratesMap,
          'lastUpdated':
              ratesResponse.isNotEmpty
                  ? ratesResponse.first['updated_at']
                  : DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      print('Error getting currency data from Supabase: $e');
      throw e;
    }
  }

  // Get currency data from API endpoint (fallback)
  Future<Map<String, dynamic>> _getCurrencyDataFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/currency'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting currency data from API: $e');
      throw e;
    }
  }

  // Convert amount between currencies
  Future<Map<String, dynamic>> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      // Try API endpoint first
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/currency/convert?amount=$amount&from=$fromCurrency&to=$toCurrency',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Fallback to direct Supabase query
        return await _convertAmountDirect(amount, fromCurrency, toCurrency);
      }
    } catch (e) {
      print('Error converting amount: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Direct conversion using Supabase
  Future<Map<String, dynamic>> _convertAmountDirect(
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

      // Get direct rate
      var rateResponse =
          await _supabase
              .from('currency_rates')
              .select('rate')
              .eq('from_currency', fromCurrency)
              .eq('to_currency', toCurrency)
              .maybeSingle();

      double? conversionRate;

      if (rateResponse != null) {
        conversionRate = (rateResponse['rate'] as num).toDouble();
      } else {
        // Try inverse rate
        rateResponse =
            await _supabase
                .from('currency_rates')
                .select('rate')
                .eq('from_currency', toCurrency)
                .eq('to_currency', fromCurrency)
                .maybeSingle();

        if (rateResponse != null) {
          conversionRate = 1.0 / (rateResponse['rate'] as num).toDouble();
        }
      }

      if (conversionRate == null) {
        throw Exception(
          'Exchange rate not found for $fromCurrency to $toCurrency',
        );
      }

      final convertedAmount = (amount * conversionRate * 100).round() / 100;

      return {
        'success': true,
        'data': {
          'originalAmount': amount,
          'convertedAmount': convertedAmount,
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'rate': conversionRate,
        },
      };
    } catch (e) {
      print('Error in direct conversion: $e');
      throw e;
    }
  }

  // Update user currency preference
  Future<void> updateUserCurrencyPreference(String currency) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user for currency preference update');
        return;
      }

      // Check if user preference already exists
      final existingPreference =
          await _supabase
              .from('user_currency_preferences')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

      if (existingPreference != null) {
        // Update existing preference
        await _supabase
            .from('user_currency_preferences')
            .update({
              'preferred_currency': currency,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      } else {
        // Insert new preference
        await _supabase.from('user_currency_preferences').insert({
          'user_id': user.id,
          'preferred_currency': currency,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      print('Successfully updated user currency preference to $currency');
    } catch (e) {
      print('Error updating user currency preference: $e');
      // Don't throw the error to prevent UI disruption
      // The currency change will still work locally
    }
  }

  // Get user currency preference
  Future<String?> getUserCurrencyPreference() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response =
          await _supabase
              .from('user_currency_preferences')
              .select('preferred_currency')
              .eq('user_id', user.id)
              .maybeSingle();

      return response?['preferred_currency'];
    } catch (e) {
      print('Error getting user currency preference: $e');
      return null;
    }
  }

  // Get exchange rate between two currencies
  Future<double?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      if (fromCurrency == toCurrency) return 1.0;

      // Try direct rate
      var response =
          await _supabase
              .from('currency_rates')
              .select('rate')
              .eq('from_currency', fromCurrency)
              .eq('to_currency', toCurrency)
              .maybeSingle();

      if (response != null) {
        return (response['rate'] as num).toDouble();
      }

      // Try inverse rate
      response =
          await _supabase
              .from('currency_rates')
              .select('rate')
              .eq('from_currency', toCurrency)
              .eq('to_currency', fromCurrency)
              .maybeSingle();

      if (response != null) {
        return 1.0 / (response['rate'] as num).toDouble();
      }

      return null;
    } catch (e) {
      print('Error getting exchange rate: $e');
      return null;
    }
  }

  // Batch convert multiple prices
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
      throw e;
    }
  }
}
