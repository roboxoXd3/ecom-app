/// Exception thrown when API request fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  /// Parse Django error format: { "detail": "..." } or { "error": { "message": "..." } }
  factory ApiException.fromResponse(dynamic data, {int? statusCode}) {
    String message = 'An error occurred';

    if (data is Map) {
      if (data['detail'] != null) {
        message = data['detail'] is String
            ? data['detail'] as String
            : data['detail'].toString();
      } else if (data['error'] is Map && data['error']['message'] != null) {
        message = data['error']['message'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    } else if (data != null) {
      message = data.toString();
    }

    return ApiException(message, statusCode: statusCode, originalError: data);
  }

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
