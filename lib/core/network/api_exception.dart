/// Exception thrown when there is no internet / the server is unreachable.
class NoInternetException implements Exception {
  final String message;
  const NoInternetException([this.message = 'No internet connection']);

  @override
  String toString() => 'NoInternetException: $message';
}

/// Exception thrown when API request fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final Map<String, List<String>>? fieldErrors;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.fieldErrors,
  });

  /// Parse Django error formats:
  ///   { "detail": "..." }
  ///   { "error": "..." }
  ///   { "message": "..." }
  ///   { "field_name": ["Error message 1", "Error message 2"] }  (validation)
  factory ApiException.fromResponse(dynamic data, {int? statusCode}) {
    String message = 'An error occurred';
    Map<String, List<String>>? fieldErrors;

    if (data is Map) {
      if (data['detail'] != null) {
        message = data['detail'] is String
            ? data['detail'] as String
            : data['detail'].toString();
      } else if (data['error'] is Map && data['error']['message'] != null) {
        message = data['error']['message'].toString();
      } else if (data['error'] is String) {
        message = data['error'] as String;
      } else if (data['message'] != null) {
        message = data['message'].toString();
      } else {
        // Django validation errors: { "field": ["error1", "error2"] }
        fieldErrors = _parseFieldErrors(data);
        if (fieldErrors.isNotEmpty) {
          message = fieldErrors.values.first.first;
        }
      }
    } else if (data != null) {
      message = data.toString();
    }

    return ApiException(
      message,
      statusCode: statusCode,
      originalError: data,
      fieldErrors: fieldErrors,
    );
  }

  /// Parse Django validation error format
  static Map<String, List<String>> _parseFieldErrors(Map data) {
    final errors = <String, List<String>>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is List) {
        errors[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        errors[key] = [value];
      }
    }
    return errors;
  }

  /// Whether this is a validation error with field-level messages
  bool get isValidationError => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get all field error messages as a single string
  String get allFieldErrors {
    if (fieldErrors == null || fieldErrors!.isEmpty) return message;
    return fieldErrors!.entries
        .map((e) => '${e.key}: ${e.value.join(", ")}')
        .join('\n');
  }

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
