import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/currency_controller.dart';

class CurrencySelectorWidget extends StatelessWidget {
  final bool isCompact;
  final bool showLabel;

  const CurrencySelectorWidget({
    super.key,
    this.isCompact = true,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyController currencyController =
        Get.find<CurrencyController>();

    return Obx(() {
      if (currencyController.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        );
      }

      if (isCompact) {
        return _buildCompactSelector(currencyController);
      } else {
        return _buildFullSelector(currencyController);
      }
    });
  }

  Widget _buildCompactSelector(CurrencyController currencyController) {
    return PopupMenuButton<String>(
      onSelected: (String currency) {
        currencyController.updateCurrency(currency);
      },
      itemBuilder: (BuildContext context) {
        return currencyController.supportedCurrencies.map((currency) {
          final isSelected =
              currency['code'] == currencyController.selectedCurrency.value;
          return PopupMenuItem<String>(
            value: currency['code'],
            child: Row(
              children: [
                Text(
                  currency['symbol'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${currency['code']} - ${currency['name']}',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyController.getCurrencySymbol(
                currencyController.selectedCurrency.value,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currencyController.selectedCurrency.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSelector(CurrencyController currencyController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Currency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(Get.context!),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currencyController.selectedCurrency.value,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  currencyController.updateCurrency(newValue);
                }
              },
              items:
                  currencyController.supportedCurrencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency['code'],
                      child: Row(
                        children: [
                          Text(
                            currency['symbol'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency['code'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  currency['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
