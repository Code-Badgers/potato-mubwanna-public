import 'package:dio/dio.dart';

import '../constants/api_paths.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenStorage, {
    required String baseUrl,
    required Dio dio,
  }) : _dio = dio,
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: dio.options.connectTimeout,
           sendTimeout: dio.options.sendTimeout,
           receiveTimeout: dio.options.receiveTimeout,
         ),
       );

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;
  Future<String?>? _refreshInFlight;

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
      final accessToken = await _accessTokenAfterUnauthorized(options);
      if (accessToken == null || accessToken.isEmpty) {
        handler.next(err);
        return;
      }

      final retryResponse = await _dio.request<dynamic>(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: {...options.headers, 'Authorization': 'Bearer $accessToken'},
          responseType: options.responseType,
          contentType: options.contentType,
          followRedirects: options.followRedirects,
          receiveDataWhenStatusError: options.receiveDataWhenStatusError,
          validateStatus: options.validateStatus,
          extra: {...options.extra, 'authRetry': true},
        ),
      );
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _accessTokenAfterUnauthorized(RequestOptions options) async {
    final storedAccessToken = await _tokenStorage.readAccessToken();
    if (storedAccessToken != null &&
        storedAccessToken.isNotEmpty &&
        options.headers['Authorization'] != 'Bearer $storedAccessToken') {
      // 다른 요청이 먼저 토큰을 회전했다면 다시 회전하지 않고 최신 토큰을 재사용한다.
      return storedAccessToken;
    }
    return _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _requestNewAccessToken();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<String?> _requestNewAccessToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
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
      return null;
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: rotatedRefreshToken,
    );
    return accessToken;
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
