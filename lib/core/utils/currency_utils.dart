import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../features/presentation/controllers/currency_controller.dart';

class CurrencyUtils {
  static CurrencyController get _currencyController =>
      Get.find<CurrencyController>();

  /// Format amount with selected currency symbol and proper comma denomination
  static String formatAmount(double amount, {int decimalPlaces = 2}) {
    try {
      final selectedCurrency = _currencyController.selectedCurrency.value;
      final currencySymbol = getCurrencySymbol(selectedCurrency);
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);

      return '$currencySymbol$formattedNumber';
    } catch (e) {
      // Fallback to NGN (primary business currency) if controller is not available
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);
      return '₦$formattedNumber';
    }
  }

  /// Format number with proper comma denomination (thousands separators)
  static String formatNumberWithCommas(double amount, int decimalPlaces) {
    final formatter = NumberFormat(
      '#,##0${decimalPlaces > 0 ? '.${'0' * decimalPlaces}' : ''}',
      'en_US',
    );
    return formatter.format(amount);
  }

  /// Format amount with currency code and commas (e.g., "1,000.00 INR")
  static String formatAmountWithCommas(
    double amount, {
    int decimalPlaces = 2,
    String? currencyCode,
  }) {
    try {
      final currency =
          currencyCode ?? _currencyController.selectedCurrency.value;
      final currencySymbol = getCurrencySymbol(currency);
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);

      return '$currencySymbol$formattedNumber';
    } catch (e) {
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);
      return '₦$formattedNumber';
    }
  }

  /// Get currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'NGN':
        return '₦';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'CNY':
        return '¥';
      default:
        return currencyCode; // Return currency code if symbol not found
    }
  }

  /// Get currency name for a currency code
  static String getCurrencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return 'Indian Rupee';
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'NGN':
        return 'Nigerian Naira';
      case 'CAD':
        return 'Canadian Dollar';
      case 'AUD':
        return 'Australian Dollar';
      case 'JPY':
        return 'Japanese Yen';
      case 'KRW':
        return 'Korean Won';
      case 'CNY':
        return 'Chinese Yuan';
      default:
        return currencyCode;
    }
  }

  /// Format amount with currency code (e.g., "1,000.00 INR")
  static String formatAmountWithCode(double amount, {int decimalPlaces = 2}) {
    try {
      final selectedCurrency = _currencyController.selectedCurrency.value;
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);
      return '$formattedNumber $selectedCurrency';
    } catch (e) {
      final formattedNumber = formatNumberWithCommas(amount, decimalPlaces);
      return '$formattedNumber NGN';
    }
  }

  /// Check if currency uses decimal places
  static bool currencyUsesDecimals(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY': // Japanese Yen
      case 'KRW': // Korean Won
        return false;
      default:
        return true;
    }
  }

  /// Format amount based on currency decimal rules with commas
  static String formatAmountSmart(double amount) {
    try {
      final selectedCurrency = _currencyController.selectedCurrency.value;
      final usesDecimals = currencyUsesDecimals(selectedCurrency);
      final decimalPlaces = usesDecimals ? 2 : 0;

      return formatAmount(amount, decimalPlaces: decimalPlaces);
    } catch (e) {
      return formatAmount(amount);
    }
  }

  /// Format price for product display with conversion and commas
  static String formatProductPrice(double price, String fromCurrency) {
    try {
      final convertedPrice = _currencyController.convertPrice(
        price,
        fromCurrency,
      );
      final selectedCurrency = _currencyController.selectedCurrency.value;
      final usesDecimals = currencyUsesDecimals(selectedCurrency);
      final decimalPlaces = usesDecimals ? 2 : 0;

      return formatAmount(convertedPrice, decimalPlaces: decimalPlaces);
    } catch (e) {
      final usesDecimals = currencyUsesDecimals('NGN');
      final decimalPlaces = usesDecimals ? 2 : 0;
      return formatAmount(price, decimalPlaces: decimalPlaces);
    }
  }

  /// Format price range (e.g., "₦1,000 - ₦5,000")
  static String formatPriceRange(
    double minPrice,
    double maxPrice, {
    String? currencyCode,
  }) {
    try {
      final currency =
          currencyCode ?? _currencyController.selectedCurrency.value;
      final usesDecimals = currencyUsesDecimals(currency);
      final decimalPlaces = usesDecimals ? 2 : 0;

      final formattedMin = formatAmountWithCommas(
        minPrice,
        decimalPlaces: decimalPlaces,
        currencyCode: currency,
      );
      final formattedMax = formatAmountWithCommas(
        maxPrice,
        decimalPlaces: decimalPlaces,
        currencyCode: currency,
      );

      return '$formattedMin - $formattedMax';
    } catch (e) {
      final formattedMin = formatAmount(minPrice);
      final formattedMax = formatAmount(maxPrice);
      return '$formattedMin - $formattedMax';
    }
  }

  /// Format discount percentage
  static String formatDiscountPercentage(
    double originalPrice,
    double discountedPrice,
  ) {
    if (originalPrice <= discountedPrice) return '';

    final discountAmount = originalPrice - discountedPrice;
    final discountPercentage = (discountAmount / originalPrice) * 100;

    return '${discountPercentage.round()}% OFF';
  }

  /// Format compact price for small displays (e.g., "₦1.2K", "₦1.5M")
  static String formatCompactPrice(double amount, {String? currencyCode}) {
    try {
      final currency =
          currencyCode ?? _currencyController.selectedCurrency.value;
      final currencySymbol = getCurrencySymbol(currency);

      if (amount >= 1000000) {
        final millions = amount / 1000000;
        return '$currencySymbol${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}M';
      } else if (amount >= 1000) {
        final thousands = amount / 1000;
        return '$currencySymbol${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}K';
      } else {
        final usesDecimals = currencyUsesDecimals(currency);
        final decimalPlaces = usesDecimals ? 2 : 0;
        return '$currencySymbol${amount.toStringAsFixed(decimalPlaces)}';
      }
    } catch (e) {
      if (amount >= 1000000) {
        final millions = amount / 1000000;
        return '₦${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}M';
      } else if (amount >= 1000) {
        final thousands = amount / 1000;
        return '₦${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}K';
      } else {
        return '₦${amount.toStringAsFixed(2)}';
      }
    }
  }
}
