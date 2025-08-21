import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/address_model.dart';
import '../../controllers/address_controller.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../widgets/google_places_autocomplete.dart';

class AddAddressScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? address;

  const AddAddressScreen({super.key, this.isEditing = false, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressSearchController = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _zipController = TextEditingController();

  // Address components from Google Places
  String _streetAddress = '';
  String _city = '';
  String _state = '';
  String _country = '';
  String _postalCode = '';
  double? _latitude;
  double? _longitude;

  bool _isDefault = false;
  bool _isLoadingLocation = false;
  final AddressController addressController = Get.find<AddressController>();

  @override
  void initState() {
    super.initState();

    // Check authentication first
    if (!AuthService.isAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Authentication Required',
          'Please log in to manage your addresses',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back(); // Go back to previous screen
      });
      return;
    }

    if (widget.isEditing && widget.address != null) {
      _nameController.text = widget.address!['name'] ?? '';
      _phoneController.text = widget.address!['phone'] ?? '';
      _streetAddress = widget.address!['address_line1'] ?? '';
      _addressLine2Controller.text = widget.address!['address_line2'] ?? '';
      _city = widget.address!['city'] ?? '';
      _state = widget.address!['state'] ?? '';
      _country = widget.address!['country'] ?? '';
      _postalCode = widget.address!['zip'] ?? '';
      _zipController.text = _postalCode;
      _isDefault = widget.address!['is_default'] ?? false;

      // Set the search field with formatted address
      _addressSearchController.text =
          '$_streetAddress, $_city, $_state $_postalCode, $_country';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressSearchController.dispose();
    _addressLine2Controller.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _onPlaceSelected(PlaceDetails placeDetails) {
    setState(() {
      _streetAddress = placeDetails.addressComponents.fullStreetAddress;
      _city = placeDetails.addressComponents.city;
      _state = placeDetails.addressComponents.state;
      _country = placeDetails.addressComponents.country;
      _postalCode = placeDetails.addressComponents.postalCode;
      _latitude = placeDetails.latitude;
      _longitude = placeDetails.longitude;
      _zipController.text = _postalCode;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationResult = await GoogleMapsService.getCurrentLocation();

      if (locationResult.isSuccess && locationResult.position != null) {
        final position = locationResult.position!;
        final addressComponents = await GoogleMapsService.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (addressComponents != null) {
          setState(() {
            // Use full street address if available, otherwise use formatted address
            _streetAddress =
                addressComponents.fullStreetAddress.isNotEmpty
                    ? addressComponents.fullStreetAddress
                    : addressComponents.formattedAddress;
            _city = addressComponents.city;
            _state = addressComponents.state;
            _country = addressComponents.country;
            _postalCode = addressComponents.postalCode;
            _latitude = position.latitude;
            _longitude = position.longitude;
            _zipController.text = _postalCode;
            _addressSearchController.text = addressComponents.formattedAddress;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Current location detected successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to get address from current location. Please try again.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Show the specific error message from LocationResult
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locationResult.errorMessage ?? 'Unknown location error',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action:
                  locationResult.errorMessage?.contains('settings') == true
                      ? SnackBarAction(
                        label: 'Settings',
                        textColor: Colors.white,
                        onPressed: () async {
                          await openAppSettings();
                        },
                      )
                      : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Address' : 'Add New Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Address Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Address Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon:
                        _isLoadingLocation
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _isLoadingLocation ? 'Getting...' : 'Use Current',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Google Places Autocomplete
              GooglePlacesAutocomplete(
                controller: _addressSearchController,
                hintText: 'Search for your address...',
                onPlaceSelected: _onPlaceSelected,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Address Line 2 (Optional)
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Apartment, suite, etc. (Optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              // Display selected address components
              if (_streetAddress.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Address:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('Street: $_streetAddress'),
                      Text('City: $_city'),
                      Text('State: $_state'),
                      Text('Country: $_country'),
                      Text('Postal Code: $_postalCode'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ZIP code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Default Address Switch
              SwitchListTile(
                title: const Text('Set as Default Address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Validate that address components are available
                      // Check if we have either a street address OR a search field filled
                      bool hasValidAddress =
                          _streetAddress.isNotEmpty ||
                          _addressSearchController.text.isNotEmpty;

                      if (!hasValidAddress) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please search and select a valid address or use current location',
                            ),
                          ),
                        );
                        return;
                      }

                      // If street address is empty but we have search text, use that
                      if (_streetAddress.isEmpty &&
                          _addressSearchController.text.isNotEmpty) {
                        _streetAddress = _addressSearchController.text;
                      }

                      if (_city.isEmpty || _state.isEmpty || _country.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please ensure all address fields are filled. Try using the search or current location.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (widget.isEditing) {
                        // Update existing address
                        addressController.updateAddress(
                          Address(
                            id: widget.address!['id'],
                            userId: '', // Will be handled by repository
                            name: _nameController.text,
                            phone: _phoneController.text,
                            addressLine1: _streetAddress,
                            addressLine2:
                                _addressLine2Controller.text.isEmpty
                                    ? null
                                    : _addressLine2Controller.text,
                            city: _city,
                            state: _state,
                            zip:
                                _postalCode.isNotEmpty
                                    ? _postalCode
                                    : _zipController.text,
                            country: _country,
                            isDefault: _isDefault,
                            createdAt: DateTime.now(),
                          ),
                        );
                      } else {
                        // Add new address
                        addressController.addAddress(
                          name: _nameController.text,
                          phone: _phoneController.text,
                          addressLine1: _streetAddress,
                          addressLine2:
                              _addressLine2Controller.text.isEmpty
                                  ? null
                                  : _addressLine2Controller.text,
                          city: _city,
                          state: _state,
                          zip:
                              _postalCode.isNotEmpty
                                  ? _postalCode
                                  : _zipController.text,
                          country: _country,
                          isDefault: _isDefault,
                        );
                      }
                    }
                  },
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
