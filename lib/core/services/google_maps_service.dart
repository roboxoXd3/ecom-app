import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../config/google_maps_config.dart';

class GoogleMapsService {
  static const String _googleMapsApiKey = GoogleMapsConfig.googleMapsApiKey;

  static const String _placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  /// Get place predictions based on input text
  static Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    try {
      final String url =
          '$_placesBaseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}'
          '&key=$_googleMapsApiKey'
          '&types=address';
      // Removed country restriction to allow worldwide address search

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting place predictions: $e');
    }
    return [];
  }

  /// Get detailed place information by place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final String url =
          '$_placesBaseUrl/details/json'
          '?place_id=$placeId'
          '&key=$_googleMapsApiKey'
          '&fields=address_components,formatted_address,geometry';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }
    return null;
  }

  /// Get current location with proper permission handling
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(
            'Location permission denied. Please allow location access to use this feature.',
          );
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          'Location permissions are permanently denied. Please enable location access in your device settings.',
        );
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationResult.success(position);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return LocationResult.error(
        'Unable to get current location. Please try again or enter your address manually.',
      );
    }
  }

  /// Reverse geocode coordinates to an [AddressComponents] record.
  ///
  /// Uses the platform `geocoding` package's [Placemark], whose field names
  /// differ from Google Places API but follow the same conceptual hierarchy.
  /// The city fallback mirrors [AddressComponents.fromGoogleComponents] so
  /// addresses entered via search and via "Use Current Location" produce
  /// consistent results — particularly important for Nigerian users whose
  /// city often arrives as `subLocality` (Lekki, Ikoyi, Maitama) rather
  /// than `locality`.
  static Future<AddressComponents?> reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;

      // First non-empty value from the candidate list (priority order).
      String firstNonEmpty(List<String?> candidates) {
        for (final value in candidates) {
          if (value != null && value.isNotEmpty) return value;
        }
        return '';
      }

      // City fallback (mirrors Google Places priority — see fromGoogleComponents):
      //   locality              — most populated cities
      //   subLocality           — UK postal towns, NG suburbs (geocoding maps both here)
      //   subAdministrativeArea — coarse fallback (NG LGAs, US counties)
      final city = firstNonEmpty([
        placemark.locality,
        placemark.subLocality,
        placemark.subAdministrativeArea,
      ]);

      final streetNumber = placemark.subThoroughfare ?? '';
      final streetName = placemark.thoroughfare ?? '';
      final state = placemark.administrativeArea ?? '';
      final country = placemark.country ?? '';
      final postalCode = placemark.postalCode ?? '';

      return AddressComponents(
        streetNumber: streetNumber,
        streetName: streetName,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
        formattedAddress: AddressComponents._formatAddress(
          streetNumber: streetNumber,
          streetName: streetName,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
        ),
      );
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final AddressComponents addressComponents;

  PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.addressComponents,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    final components = json['address_components'] as List? ?? [];

    return PlaceDetails(
      formattedAddress: json['formatted_address'] ?? '',
      latitude: geometry?['lat']?.toDouble() ?? 0.0,
      longitude: geometry?['lng']?.toDouble() ?? 0.0,
      addressComponents: AddressComponents.fromGoogleComponents(components),
    );
  }
}

class AddressComponents {
  final String streetNumber;
  final String streetName;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String formattedAddress;

  AddressComponents({
    required this.streetNumber,
    required this.streetName,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.formattedAddress,
  });

  factory AddressComponents.fromGoogleComponents(List<dynamic> components) {
    // Return the long_name of the first component whose 'types' array
    // contains any of [typesPriority], scanning in priority order.
    // Returns empty string if no match.
    String findFirst(List<String> typesPriority) {
      for (final type in typesPriority) {
        for (final component in components) {
          final types = (component['types'] as List?) ?? const [];
          if (types.contains(type)) {
            return component['long_name']?.toString() ?? '';
          }
        }
      }
      return '';
    }

    final streetNumber = findFirst(['street_number']);
    final streetName = findFirst(['route']);

    // City varies by country in Google's response. Priority order:
    //   locality                     — US, India, most large NG cities (Lagos, Abuja proper)
    //   postal_town                  — UK (Telford, Manchester), NL, parts of DE
    //   sublocality_level_1          — NG suburbs (Lekki, Ikoyi, Maitama, Wuse)
    //   sublocality                  — broader fallback for sub-areas
    //   administrative_area_level_2  — last resort: NG LGAs, US counties
    final city = findFirst([
      'locality',
      'postal_town',
      'sublocality_level_1',
      'sublocality',
      'administrative_area_level_2',
    ]);

    final state = findFirst(['administrative_area_level_1']);
    final country = findFirst(['country']);
    final postalCode = findFirst(['postal_code']);

    return AddressComponents(
      streetNumber: streetNumber,
      streetName: streetName,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      formattedAddress: _formatAddress(
        streetNumber: streetNumber,
        streetName: streetName,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
      ),
    );
  }

  String get fullStreetAddress => '$streetNumber $streetName'.trim();

  /// Build a human-readable address while eliding empty components.
  ///
  /// Many Nigerian addresses have no postal code, and the parser may
  /// occasionally miss a city/state. Naively joining with commas produces
  /// noise like `"Lagos, , Nigeria"`. This formatter skips empty parts so
  /// the output stays clean regardless of which components are present.
  static String _formatAddress({
    required String streetNumber,
    required String streetName,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) {
    String joinNonEmpty(List<String> parts, String separator) =>
        parts.where((p) => p.isNotEmpty).join(separator);

    return joinNonEmpty([
      joinNonEmpty([streetNumber, streetName], ' '),
      city,
      joinNonEmpty([state, postalCode], ' '),
      country,
    ], ', ');
  }
}

class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String? errorMessage;

  LocationResult._({required this.isSuccess, this.position, this.errorMessage});

  factory LocationResult.success(Position position) {
    return LocationResult._(isSuccess: true, position: position);
  }

  factory LocationResult.error(String message) {
    return LocationResult._(isSuccess: false, errorMessage: message);
  }
}
