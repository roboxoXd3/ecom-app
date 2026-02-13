import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/token_storage_service.dart';
import 'api_exception.dart';

/// HTTP client for BeSmart Django backend with JWT auth and token refresh.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  final _tokenStorage = TokenStorageService();

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.fullBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for login, register, refresh
        final path = options.path.toLowerCase();
        if (path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh')) {
          return handler.next(options);
        }
        final token = _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              final opts = error.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${_tokenStorage.getAccessToken()}';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh/',
        data: {'refresh': refresh},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final access = response.data['access'] as String?;
        if (access != null) {
          await _tokenStorage.saveTokens(
            accessToken: access,
            refreshToken: refresh,
          );
          return true;
        }
      }
    } catch (_) {
      await _tokenStorage.clearTokens();
    }
    return false;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}

/// Throws [ApiException] on DioError
void throwOnError(DioException e) {
  if (e.response != null) {
    final statusCode = e.response!.statusCode;
    final data = e.response!.data;
    throw ApiException.fromResponse(data, statusCode: statusCode);
  }
  throw ApiException(
    e.message ?? 'Network error',
    originalError: e,
  );
}
