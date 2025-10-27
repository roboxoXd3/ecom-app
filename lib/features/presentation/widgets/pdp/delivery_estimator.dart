import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/theme/app_theme.dart';

class DeliveryEstimator extends StatefulWidget {
  final DeliveryInfo? deliveryInfo;
  final Function(String pincode)? onPincodeCheck;

  const DeliveryEstimator({super.key, this.deliveryInfo, this.onPincodeCheck});

  @override
  State<DeliveryEstimator> createState() => _DeliveryEstimatorState();
}

class _DeliveryEstimatorState extends State<DeliveryEstimator> {
  final TextEditingController _pincodeController = TextEditingController();
  bool _isLoading = false;
  bool _hasChecked = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery & Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 12),

          // Pincode Input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter pincode',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _errorMessage,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkDelivery,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Check'),
                ),
              ),
            ],
          ),

          if (_hasChecked && widget.deliveryInfo != null) ...[
            const SizedBox(height: 16),
            _buildDeliveryInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final info = widget.deliveryInfo!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Delivery ETA
          if (info.etaMinDays != null && info.etaMaxDays != null)
            _buildInfoRow(
              Icons.local_shipping,
              'Delivery',
              '${info.etaMinDays}-${info.etaMaxDays} days',
              Colors.green,
            ),

          // Shipping Fee
          _buildInfoRow(
            Icons.currency_rupee,
            'Shipping',
            info.freeDelivery
                ? 'FREE'
                : info.shippingFee != null
                ? CurrencyUtils.formatAmount(info.shippingFee!, decimalPlaces: 0)
                : 'Calculated at checkout',
            info.freeDelivery ? Colors.green : Colors.orange,
          ),

          // COD Availability
          _buildInfoRow(
            Icons.money,
            'Cash on Delivery',
            info.codEligible ? 'Available' : 'Not Available',
            info.codEligible ? Colors.green : Colors.red,
          ),

          // Return Policy
          _buildInfoRow(
            Icons.keyboard_return,
            'Returns',
            '${info.returnWindowDays} days return policy',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkDelivery() async {
    final pincode = _pincodeController.text.trim();

    if (pincode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter pincode';
      });
      return;
    }

    if (pincode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter valid 6-digit pincode';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (widget.onPincodeCheck != null) {
      widget.onPincodeCheck!(pincode);
    }

    setState(() {
      _isLoading = false;
      _hasChecked = true;
    });
  }
}
