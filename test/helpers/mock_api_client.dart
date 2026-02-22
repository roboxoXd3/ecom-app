import 'package:dio/dio.dart';
import 'package:ecom_app/core/network/api_client.dart';

/// Sets up a mock Dio that returns preconfigured responses via a DioAdapter.
/// Usage:
///   final mockDio = createMockDio();
///   mockDio.addResponse('/products/123/reviews/', responseData);
///   setupMockApiClient(mockDio.dio);
///   // now ApiClient.instance.get/post will use the mock
class MockDioHelper {
  final Dio dio;
  final List<_MockRoute> _routes = [];

  MockDioHelper() : dio = Dio(BaseOptions(baseUrl: 'http://test'));

  void addGetResponse(String path, dynamic data, {int statusCode = 200}) {
    _routes.add(_MockRoute('GET', path, data, statusCode));
  }

  void addPostResponse(String path, dynamic data, {int statusCode = 200}) {
    _routes.add(_MockRoute('POST', path, data, statusCode));
  }

  void addPatchResponse(String path, dynamic data, {int statusCode = 200}) {
    _routes.add(_MockRoute('PATCH', path, data, statusCode));
  }

  void addDeleteResponse(String path, dynamic data, {int statusCode = 200}) {
    _routes.add(_MockRoute('DELETE', path, data, statusCode));
  }

  void addErrorResponse(String path, int statusCode, dynamic data, {String method = 'GET'}) {
    _routes.add(_MockRoute(method, path, data, statusCode, isError: true));
  }

  void install() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final match = _routes.firstWhere(
          (r) =>
              r.method == options.method &&
              options.path.contains(r.path),
          orElse: () => _MockRoute('GET', '', null, 404, isError: true),
        );

        if (match.isError || match.statusCode >= 400) {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: match.statusCode,
              data: match.data,
            ),
            type: DioExceptionType.badResponse,
          ));
        } else {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: match.statusCode,
            data: match.data,
          ));
        }
      },
    ));

    ApiClient.setDioForTesting(dio);
  }
}

class _MockRoute {
  final String method;
  final String path;
  final dynamic data;
  final int statusCode;
  final bool isError;

  _MockRoute(this.method, this.path, this.data, this.statusCode, {this.isError = false});
}
