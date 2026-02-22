import 'package:flutter_dotenv/flutter_dotenv.dart';

/// BeSmart Django backend API configuration.
class ApiConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://web-production-7cd3c.up.railway.app';

  static String get apiPrefix => '/api';

  /// Full base URL including /api prefix
  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}
