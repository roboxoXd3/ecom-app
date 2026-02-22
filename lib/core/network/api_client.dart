import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'api_exception.dart';

/// HTTP client for BeSmart Django backend.
/// Reads access token from local storage via AuthService.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late Dio _dio;

  /// Completer used to coalesce concurrent refresh attempts.
  /// All 403/401 requests wait on this single Future.
  Completer<bool>? _refreshCompleter;

  /// Called when both access & refresh tokens are dead.
  /// Set this from main.dart or InitialBindings to handle re-login navigation.
  static void Function()? onSessionExpired;

  /// Tracks when the last no-internet banner was shown to avoid spamming.
  DateTime? _lastNoInternetBanner;

  Dio get dio => _dio;

  /// Replace the internal Dio instance (for testing only).
  static void setDioForTesting(Dio dio) {
    _instance._dio = dio;
  }

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.fullBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path.toLowerCase();
          if (path.contains('/users/login') ||
              path.contains('/users/register') ||
              path.contains('/users/token/refresh')) {
            return handler.next(options);
          }

          final token = AuthService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Detect connectivity/network errors before anything else
          final isNetworkError =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              (error.message != null &&
                  (error.message!.contains('SocketException') ||
                      error.message!.contains('Connection refused') ||
                      error.message!.contains('Network is unreachable') ||
                      error.message!.contains('Failed host lookup')));

          if (isNetworkError) {
            _showNoInternetBanner();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: const NoInternetException(),
                type: error.type,
              ),
            );
          }

          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path.toLowerCase();

          final isAuthEndpoint =
              path.contains('/users/login') ||
              path.contains('/users/register') ||
              path.contains('/users/token/refresh');

          if ((statusCode == 401 || statusCode == 403) &&
              !isAuthEndpoint &&
              AuthService.isAuthenticated()) {
            final refreshed = await _refreshTokenOnce();
            if (refreshed) {
              final token = AuthService.getAccessToken();
              if (token != null && token.isNotEmpty) {
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $token';
                try {
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                } catch (retryError) {
                  if (retryError is DioException) {
                    return handler.next(retryError);
                  }
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Shows a no-internet banner at most once every 5 seconds to avoid spam
  /// when multiple requests fail simultaneously.
  void _showNoInternetBanner() {
    final now = DateTime.now();
    if (_lastNoInternetBanner != null &&
        now.difference(_lastNoInternetBanner!).inSeconds < 5) {
      return;
    }
    _lastNoInternetBanner = now;

    // Run on next frame so it doesn't fire during a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) return;
      Get.snackbar(
        'No Internet',
        'Check your connection and try again',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF111111),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 24),
        shouldIconPulse: false,
      );
    });
  }

  /// Ensures only one refresh runs at a time.
  /// Concurrent callers await the same Future.
  Future<bool> _refreshTokenOnce() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final result = await _refreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Refresh the access token using the refresh token via Django API.
  /// If the refresh token is also expired, clears the session and
  /// navigates to the login screen.
  Future<bool> _refreshToken() async {
    final refreshToken = AuthService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      print('🔑 Token refresh: No refresh token — forcing re-login');
      await _forceReLogin();
      return false;
    }

    try {
      print('🔑 Token refresh: Attempting refresh...');
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConfig.fullBaseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      ).post('/users/token/refresh/', data: {'refresh_token': refreshToken});

      final data = response.data;
      if (data is Map && data['access_token'] != null) {
        await AuthService.updateAccessToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await AuthService.updateRefreshToken(data['refresh_token']);
        }
        print('🔑 Token refresh: Success');
        return true;
      }
    } catch (e) {
      print('🔑 Token refresh: Failed — forcing re-login');
      await _forceReLogin();
    }
    return false;
  }

  /// Clear the dead session and notify the app to show the login screen.
  Future<void> _forceReLogin() async {
    await AuthService.clearSession();
    onSessionExpired?.call();
  }

  // ---------------------------------------------------------------------------
  // HTTP methods
  // ---------------------------------------------------------------------------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ---------------------------------------------------------------------------
  // Multipart upload (for image search etc.)
  // ---------------------------------------------------------------------------

  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onSendProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: formData,
      queryParameters: queryParameters,
      onSendProgress: onSendProgress,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  // ---------------------------------------------------------------------------
  // Pagination helper
  // ---------------------------------------------------------------------------

  /// Extract the `results` list from a Django paginated response.
  /// If the response is already a plain list, returns it as-is.
  static List<dynamic> unwrapResults(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    }
    if (data is List) return data;
    return [];
  }
}

/// Throws [ApiException] on DioError
void throwOnError(DioException e) {
  if (e.response != null) {
    final statusCode = e.response!.statusCode;
    final data = e.response!.data;
    throw ApiException.fromResponse(data, statusCode: statusCode);
  }
  throw ApiException(e.message ?? 'Network error', originalError: e);
}
