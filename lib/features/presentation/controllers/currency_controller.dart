import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/services/currency_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/currency_utils.dart';

class CurrencyController extends GetxController {
  final CurrencyService _currencyService = CurrencyService();
  final GetStorage _storage = GetStorage();

  // Observable variables
  final RxString selectedCurrency =
      'NGN'.obs; // Default to NGN (primary business currency)
  final RxList<Map<String, dynamic>> supportedCurrencies =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> exchangeRates = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString lastUpdated = ''.obs;

  // Default currencies as fallback (NGN first as primary business currency)
  final List<Map<String, dynamic>> _defaultCurrencies = [
    {
      'code': 'NGN',
      'symbol': '₦',
      'name': 'Nigerian Naira',
    }, // Primary business currency
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedCurrency();
    loadCurrencyData();
  }

  // Load saved currency preference
  void _loadSavedCurrency() {
    final savedCurrency = _storage.read('selected_currency');
    if (savedCurrency != null) {
      selectedCurrency.value = savedCurrency;
    }
  }

  // Save currency preference
  void _saveCurrency(String currency) {
    _storage.write('selected_currency', currency);
  }

  // Load currency data from backend
  Future<void> loadCurrencyData() async {
    try {
      isLoading.value = true;
      error.value = '';

      final data = await _currencyService.getCurrencyData();

      if (data['success'] == true) {
        final currencyData = data['data'];

        // Update supported currencies
        if (currencyData['supportedCurrencies'] != null) {
          supportedCurrencies.value = List<Map<String, dynamic>>.from(
            currencyData['supportedCurrencies'],
          );
        } else {
          supportedCurrencies.value = _defaultCurrencies;
        }

        // Update exchange rates
        if (currencyData['exchangeRates'] != null) {
          exchangeRates.value = Map<String, dynamic>.from(
            currencyData['exchangeRates'],
          );
        }

        // Update last updated timestamp
        if (currencyData['lastUpdated'] != null) {
          lastUpdated.value = currencyData['lastUpdated'];
        }

        // Validate selected currency is supported
        final isSupported = supportedCurrencies.any(
          (currency) => currency['code'] == selectedCurrency.value,
        );

        if (!isSupported && supportedCurrencies.isNotEmpty) {
          selectedCurrency.value = supportedCurrencies.first['code'];
          _saveCurrency(selectedCurrency.value);
        }
      } else {
        throw Exception(data['error'] ?? 'Failed to load currency data');
      }
    } catch (e) {
      print('Error loading currency data: $e');
      error.value = 'Failed to load currencies';

      // Use default currencies as fallback
      supportedCurrencies.value = _defaultCurrencies;

      // Show error to user
      SnackbarUtils.showError('Currency data unavailable, using defaults');
    } finally {
      isLoading.value = false;
    }
  }

  // Update selected currency
  Future<void> updateCurrency(String newCurrency) async {
    if (newCurrency == selectedCurrency.value) return;

    try {
      // Validate currency is supported
      final isSupported = supportedCurrencies.any(
        (currency) => currency['code'] == newCurrency,
      );

      if (!isSupported) {
        throw Exception('Currency $newCurrency is not supported');
      }

      selectedCurrency.value = newCurrency;
      _saveCurrency(newCurrency);

      // Optionally update user preference in backend
      await _updateUserCurrencyPreference(newCurrency);

      SnackbarUtils.showSuccess('Currency updated to $newCurrency');
    } catch (e) {
      print('Error updating currency: $e');
      SnackbarUtils.showError('Failed to update currency');
    }
  }

  // Update user currency preference in backend
  Future<void> _updateUserCurrencyPreference(String currency) async {
    try {
      await _currencyService.updateUserCurrencyPreference(currency);
    } catch (e) {
      print('Error updating user currency preference: $e');
      // Don't show error to user as this is not critical
    }
  }

  // Convert price from one currency to another
  double convertPrice(double price, String fromCurrency, {String? toCurrency}) {
    final targetCurrency = toCurrency ?? selectedCurrency.value;

    if (fromCurrency == targetCurrency) {
      return price;
    }

    try {
      // Get conversion rate
      final rate = getConversionRate(fromCurrency, targetCurrency);
      if (rate != null) {
        return (price * rate * 100).round() / 100; // Round to 2 decimal places
      }
    } catch (e) {
      print('Error converting price: $e');
    }

    // Return original price if conversion fails
    return price;
  }

  // Get conversion rate between two currencies (enhanced with cross-currency support)
  double? getConversionRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;

    // Direct rate (from -> to)
    if (exchangeRates[fromCurrency] != null &&
        exchangeRates[fromCurrency][toCurrency] != null) {
      return (exchangeRates[fromCurrency][toCurrency]['rate'] as num)
          .toDouble();
    }

    // Inverse rate (to -> from)
    if (exchangeRates[toCurrency] != null &&
        exchangeRates[toCurrency][fromCurrency] != null) {
      final inverseRate =
          (exchangeRates[toCurrency][fromCurrency]['rate'] as num).toDouble();
      return 1.0 / inverseRate;
    }

    // Cross-conversion via USD (most common case)
    if (fromCurrency != 'USD' && toCurrency != 'USD') {
      // Convert from source currency to USD first
      double? usdRate;

      if (exchangeRates[fromCurrency] != null &&
          exchangeRates[fromCurrency]['USD'] != null) {
        // Direct rate to USD
        usdRate =
            (exchangeRates[fromCurrency]['USD']['rate'] as num).toDouble();
      } else if (exchangeRates['USD'] != null &&
          exchangeRates['USD'][fromCurrency] != null) {
        // Inverse rate from USD
        final inverseRate =
            (exchangeRates['USD'][fromCurrency]['rate'] as num).toDouble();
        usdRate = 1.0 / inverseRate;
      }

      if (usdRate == null) {
        print('No USD conversion rate found for $fromCurrency');
        return null;
      }

      // Convert from USD to target currency
      if (exchangeRates['USD'] != null &&
          exchangeRates['USD'][toCurrency] != null) {
        // Direct rate from USD
        final targetRate =
            (exchangeRates['USD'][toCurrency]['rate'] as num).toDouble();
        return usdRate * targetRate;
      } else if (exchangeRates[toCurrency] != null &&
          exchangeRates[toCurrency]['USD'] != null) {
        // Inverse rate to USD
        final inverseTargetRate =
            (exchangeRates[toCurrency]['USD']['rate'] as num).toDouble();
        return usdRate / inverseTargetRate;
      }

      print('No USD conversion rate found for $toCurrency');
      return null;
    }

    // Convert to/from USD
    if (fromCurrency == 'USD') {
      if (exchangeRates['USD'] != null &&
          exchangeRates['USD'][toCurrency] != null) {
        return (exchangeRates['USD'][toCurrency]['rate'] as num).toDouble();
      }
    }

    if (toCurrency == 'USD') {
      if (exchangeRates[fromCurrency] != null &&
          exchangeRates[fromCurrency]['USD'] != null) {
        return (exchangeRates[fromCurrency]['USD']['rate'] as num).toDouble();
      }
    }

    print('No exchange rate found for $fromCurrency to $toCurrency');
    return null;
  }

  // Get currency symbol by code
  String getCurrencySymbol(String currencyCode) {
    final currency = supportedCurrencies.firstWhereOrNull(
      (currency) => currency['code'] == currencyCode,
    );
    return currency?['symbol'] ?? currencyCode;
  }

  // Get currency name by code
  String getCurrencyName(String currencyCode) {
    final currency = supportedCurrencies.firstWhereOrNull(
      (currency) => currency['code'] == currencyCode,
    );
    return currency?['name'] ?? currencyCode;
  }

  // Format price with currency symbol and proper comma denomination
  String formatPrice(
    double price, {
    String? currencyCode,
    bool showSymbol = true,
  }) {
    final currency = currencyCode ?? selectedCurrency.value;

    if (showSymbol) {
      return CurrencyUtils.formatAmountWithCommas(
        price,
        currencyCode: currency,
      );
    } else {
      final usesDecimals = CurrencyUtils.currencyUsesDecimals(currency);
      final decimalPlaces = usesDecimals ? 2 : 0;
      return CurrencyUtils.formatNumberWithCommas(price, decimalPlaces);
    }
  }

  // Format price with currency conversion and proper comma denomination
  String formatConvertedPrice(
    double price,
    String fromCurrency, {
    bool showSymbol = true,
  }) {
    final convertedPrice = convertPrice(price, fromCurrency);
    return formatPrice(convertedPrice, showSymbol: showSymbol);
  }

  // Format product price for listings with proper comma denomination
  Map<String, String> formatProductPrices(Map<String, dynamic> product) {
    final productCurrency = product['currency'] ?? 'USD';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final mrp = (product['mrp'] as num?)?.toDouble();
    final salePrice = (product['sale_price'] as num?)?.toDouble();

    return {
      'price': formatConvertedPrice(price, productCurrency),
      'mrp': mrp != null ? formatConvertedPrice(mrp, productCurrency) : '',
      'salePrice':
          salePrice != null
              ? formatConvertedPrice(salePrice, productCurrency)
              : '',
    };
  }

  // Get formatted price for a single product field with proper comma denomination
  String getFormattedProductPrice(dynamic price, String? productCurrency) {
    if (price == null) return '';
    final priceValue = (price as num).toDouble();
    final currency = productCurrency ?? 'USD';
    return formatConvertedPrice(priceValue, currency);
  }

  // Refresh currency data
  Future<void> refreshCurrencyData() async {
    await loadCurrencyData();
  }

  // Check if currency data is stale (older than 1 hour)
  bool get isCurrencyDataStale {
    if (lastUpdated.value.isEmpty) return true;

    try {
      final lastUpdateTime = DateTime.parse(lastUpdated.value);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);

      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }

  // Auto-refresh currency data if stale
  Future<void> autoRefreshIfStale() async {
    if (isCurrencyDataStale) {
      await refreshCurrencyData();
    }
  }
}
