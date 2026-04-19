class ApiConfig {
  static String get baseUrl => "https://api.xbesmart.com";

  static String get apiPrefix => '/api';

  /// Full base URL including /api prefix
  static String get fullBaseUrl => '$baseUrl$apiPrefix';
}
