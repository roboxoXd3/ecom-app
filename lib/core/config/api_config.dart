import 'package:flutter_dotenv/flutter_dotenv.dart';

/// BeSmart Django backend API configuration.
class ApiConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://besmart.up.railway.app';

  static String get apiPrefix => '/api';

  /// Full base URL including /api (e.g. https://besmart.up.railway.app/api)
  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}
