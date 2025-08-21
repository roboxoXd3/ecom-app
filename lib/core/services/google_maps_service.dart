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
          '&types=address'
          '&components=country:us|country:ca|country:gb|country:au'; // Add more countries as needed

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
      print('Error getting place predictions: $e');
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
      print('Error getting place details: $e');
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
      print('Error getting current location: $e');
      return LocationResult.error(
        'Unable to get current location. Please try again or enter your address manually.',
      );
    }
  }

  /// Reverse geocode coordinates to address
  static Future<AddressComponents?> reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return AddressComponents(
          streetNumber: placemark.subThoroughfare ?? '',
          streetName: placemark.thoroughfare ?? '',
          city: placemark.locality ?? '',
          state: placemark.administrativeArea ?? '',
          country: placemark.country ?? '',
          postalCode: placemark.postalCode ?? '',
          formattedAddress:
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}',
        );
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
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
    String streetNumber = '';
    String streetName = '';
    String city = '';
    String state = '';
    String country = '';
    String postalCode = '';

    for (var component in components) {
      final types = component['types'] as List<dynamic>;
      final longName = component['long_name'] ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        streetName = longName;
      } else if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    return AddressComponents(
      streetNumber: streetNumber,
      streetName: streetName,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      formattedAddress:
          '$streetNumber $streetName, $city, $state $postalCode, $country',
    );
  }

  String get fullStreetAddress => '$streetNumber $streetName'.trim();
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
