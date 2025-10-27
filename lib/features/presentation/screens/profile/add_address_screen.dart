import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/address_model.dart';
import '../../controllers/address_controller.dart';
import '../../../../core/services/google_maps_service.dart';
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
    if (widget.isEditing && widget.address != null) {
      _nameController.text = widget.address!['name'] ?? '';
      _phoneController.text = widget.address!['phone'] ?? '';
      _addressSearchController.text = widget.address!['address_line1'] ?? '';
      _streetAddress = widget.address!['address_line1'] ?? '';
      _addressLine2Controller.text = widget.address!['address_line2'] ?? '';
      _city = widget.address!['city'] ?? '';
      _state = widget.address!['state'] ?? '';
      _postalCode = widget.address!['zip'] ?? '';
      _country = widget.address!['country'] ?? '';
      _zipController.text = widget.address!['zip'] ?? '';
      _isDefault = widget.address!['is_default'] ?? false;
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

  void _onPlaceSelected(PlaceDetails place) {
    setState(() {
      _streetAddress =
          '${place.addressComponents.streetNumber} ${place.addressComponents.streetName}'
              .trim();
      _city = place.addressComponents.city;
      _state = place.addressComponents.state;
      _country = place.addressComponents.country;
      _postalCode = place.addressComponents.postalCode;
      _latitude = place.latitude;
      _longitude = place.longitude;

      // Update the search controller with the formatted address
      _addressSearchController.text = place.formattedAddress;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      // Request location permission
      var status = await Permission.location.request();

      if (status.isGranted) {
        print('Location permission granted, getting current location...');

        final locationResult = await GoogleMapsService.getCurrentLocation();

        print('Got location: $locationResult');

        if (locationResult.isSuccess && locationResult.position != null) {
          // Get place details from coordinates using reverse geocoding
          final addressComponents = await GoogleMapsService.reverseGeocode(
            locationResult.position!.latitude,
            locationResult.position!.longitude,
          );

          if (addressComponents != null) {
            setState(() {
              _streetAddress = addressComponents.fullStreetAddress;
              _city = addressComponents.city;
              _state = addressComponents.state;
              _country = addressComponents.country;
              _postalCode = addressComponents.postalCode;
              _latitude = locationResult.position!.latitude;
              _longitude = locationResult.position!.longitude;

              // Update the search controller with the formatted address
              _addressSearchController.text =
                  addressComponents.formattedAddress;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address retrieved from your location!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location retrieved but could not get address details. Please use search.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  locationResult.errorMessage ??
                      'Could not retrieve location. Please try again.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Address' : 'Add New Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Please enter your name'
                            : null,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Please enter your phone number'
                            : null,
              ),
              const SizedBox(height: 16),

              // Google Places Autocomplete
              GooglePlacesAutocomplete(
                controller: _addressSearchController,
                hintText: 'Search for your address',
                onPlaceSelected: _onPlaceSelected,
              ),
              const SizedBox(height: 8),

              // Current Location Button
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon:
                    _isLoadingLocation
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.my_location),
                label: Text(
                  _isLoadingLocation
                      ? 'Getting Location...'
                      : 'Use Current Location',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),

              // Address Line 2 Field
              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Apartment, Suite, etc. (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Zip Code Field (optional if not from Google Places)
              if (_postalCode.isEmpty)
                Column(
                  children: [
                    TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(
                        labelText: 'Zip Code',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Display selected address components (read-only)
              if (_city.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Address:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Street: $_streetAddress'),
                      Text('City: $_city'),
                      Text('State: $_state'),
                      Text('Zip: $_postalCode'),
                      Text('Country: $_country'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Set as Default Checkbox
              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        addressController.isLoading.value
                            ? null
                            : () async {
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
                                  _streetAddress =
                                      _addressSearchController.text;
                                }

                                if (_city.isEmpty ||
                                    _state.isEmpty ||
                                    _country.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please ensure all address fields are filled. Try using the search or current location.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Handle address saving directly without controller navigation
                                String? addressIdToReturn;

                                if (widget.isEditing) {
                                  // Update existing address
                                  await addressController.updateAddress(
                                    Address(
                                      id: widget.address!['id'],
                                      userId:
                                          '', // Will be handled by repository
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
                                  // Return will be handled by updateAddress's Get.back()
                                } else {
                                  // Add new address
                                  print(
                                    'AddAddressScreen: Starting address save...',
                                  );

                                  addressIdToReturn = await addressController
                                      .addAddress(
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

                                  if (addressIdToReturn != null) {
                                    print(
                                      'AddAddressScreen: Address created successfully with ID: $addressIdToReturn',
                                    );

                                    // Navigate back immediately with the address ID
                                    if (mounted && Navigator.canPop(context)) {
                                      print(
                                        'AddAddressScreen: Navigating back with result: $addressIdToReturn',
                                      );
                                      Navigator.of(
                                        context,
                                      ).pop(addressIdToReturn);
                                    }
                                  } else {
                                    print(
                                      'AddAddressScreen: Address creation failed',
                                    );
                                  }
                                }
                              }
                            },
                    child:
                        addressController.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Save Address'),
                  ),
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
