import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenStorage, {
    required String baseUrl,
    required Dio dio,
  })  : _dio = dio,
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (!_canRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        handler.next(err);
        return;
      }

      final tokenResponse = await _refreshDio.post<Map<String, dynamic>>(
        ApiPaths.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final tokenData = tokenResponse.data?['data'] as Map<String, dynamic>?;
      final accessToken = tokenData?['accessToken'] as String?;
      final rotatedRefreshToken = tokenData?['refreshToken'] as String?;
      if (accessToken == null ||
          accessToken.isEmpty ||
          rotatedRefreshToken == null ||
          rotatedRefreshToken.isEmpty) {
        handler.next(err);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
      );

      final retryResponse = await _dio.request<dynamic>(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: {
            ...options.headers,
            'Authorization': 'Bearer $accessToken',
          },
          responseType: options.responseType,
          contentType: options.contentType,
          followRedirects: options.followRedirects,
          receiveDataWhenStatusError: options.receiveDataWhenStatusError,
          validateStatus: options.validateStatus,
          extra: {
            ...options.extra,
            'authRetry': true,
          },
        ),
      );
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _canRefresh(DioException err) {
    final options = err.requestOptions;
    return err.response?.statusCode == 401 &&
        options.extra['authRetry'] != true &&
        !_isAuthEndpoint(options.path);
  }

  bool _isAuthEndpoint(String path) {
    return path == ApiPaths.authKakao ||
        path == ApiPaths.authRefresh ||
        path == ApiPaths.authLogout;
  }
}
