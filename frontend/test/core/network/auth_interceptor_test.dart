import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/dio_client.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';

void main() {
  late _AuthTestServer server;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    server = await _AuthTestServer.start();
  });

  tearDown(() => server.close());

  test('concurrent 401 responses share one refresh and both retry', () async {
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'expired-access-token',
      refreshToken: 'valid-refresh-token',
    );
    final dio = DioClient(
      tokenStorage: tokenStorage,
      baseUrl: server.baseUrl,
    ).dio;

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected/first'),
      dio.get<Map<String, dynamic>>('/protected/second'),
    ]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(server.refreshRequests, 1);
    expect(server.successfulRetries, 2);
    expect(await tokenStorage.readAccessToken(), 'rotated-access-token');
    expect(await tokenStorage.readRefreshToken(), 'rotated-refresh-token');
  });

  test('a late concurrent 401 reuses the token rotated by the first request',
      () async {
    await server.close();
    server = await _AuthTestServer.start(
      delaySecondUnauthorizedUntilFirstRetry: true,
    );
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'expired-access-token',
      refreshToken: 'valid-refresh-token',
    );
    final dio = DioClient(
      tokenStorage: tokenStorage,
      baseUrl: server.baseUrl,
    ).dio;

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected/first'),
      dio.get<Map<String, dynamic>>('/protected/second'),
    ]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(server.refreshRequests, 1);
    expect(server.successfulRetries, 2);
  });

  test('concurrent requests keep their original 401 when refresh fails',
      () async {
    await server.close();
    server = await _AuthTestServer.start(refreshSucceeds: false);
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'expired-access-token',
      refreshToken: 'invalid-refresh-token',
    );
    final dio = DioClient(
      tokenStorage: tokenStorage,
      baseUrl: server.baseUrl,
    ).dio;

    final errors = await Future.wait([
      _captureDioError(dio.get<void>('/protected/first')),
      _captureDioError(dio.get<void>('/protected/second')),
    ]);

    expect(
      errors.map((error) => error.response?.statusCode),
      everyElement(HttpStatus.unauthorized),
    );
    expect(server.refreshRequests, 1);
    expect(server.successfulRetries, 0);
  });

  test('auth endpoints and retried requests do not start token refresh',
      () async {
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'expired-access-token',
      refreshToken: 'valid-refresh-token',
    );
    final dio = DioClient(
      tokenStorage: tokenStorage,
      baseUrl: server.baseUrl,
    ).dio;

    final errors = await Future.wait([
      _captureDioError(dio.post<void>('/auth/logout')),
      _captureDioError(
        dio.get<void>(
          '/protected/already-retried',
          options: Options(extra: {'authRetry': true}),
        ),
      ),
    ]);

    expect(
      errors.map((error) => error.response?.statusCode),
      everyElement(HttpStatus.unauthorized),
    );
    expect(server.refreshRequests, 0);
  });
}

Future<DioException> _captureDioError(Future<Response<void>> request) async {
  try {
    await request;
    throw StateError('요청이 실패해야 합니다.');
  } on DioException catch (error) {
    return error;
  }
}

class _AuthTestServer {
  _AuthTestServer._(
    this._server, {
    required this.refreshSucceeds,
    required this.delaySecondUnauthorizedUntilFirstRetry,
  }) {
    _subscription = _server.listen(_handle);
  }

  static Future<_AuthTestServer> start({
    bool refreshSucceeds = true,
    bool delaySecondUnauthorizedUntilFirstRetry = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _AuthTestServer._(
      server,
      refreshSucceeds: refreshSucceeds,
      delaySecondUnauthorizedUntilFirstRetry:
          delaySecondUnauthorizedUntilFirstRetry,
    );
  }

  final HttpServer _server;
  final bool refreshSucceeds;
  final bool delaySecondUnauthorizedUntilFirstRetry;
  final Completer<void> _bothInitialRequestsFailed = Completer<void>();
  final Completer<void> _firstRetrySucceeded = Completer<void>();
  late final StreamSubscription<HttpRequest> _subscription;

  int initialUnauthorizedRequests = 0;
  int refreshRequests = 0;
  int successfulRetries = 0;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}/api';

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path == '/api/auth/refresh') {
      await _handleRefresh(request);
      return;
    }

    final authorization =
        request.headers.value(HttpHeaders.authorizationHeader);
    if (authorization == 'Bearer expired-access-token') {
      initialUnauthorizedRequests++;
      if (initialUnauthorizedRequests == 2) {
        _bothInitialRequestsFailed.complete();
      }
      if (initialUnauthorizedRequests == 2 &&
          delaySecondUnauthorizedUntilFirstRetry) {
        await _firstRetrySucceeded.future;
      }
      await _respond(request, HttpStatus.unauthorized, {
        'success': false,
        'message': 'access token이 만료되었습니다.',
      });
      return;
    }

    if (authorization == 'Bearer rotated-access-token') {
      successfulRetries++;
      if (!_firstRetrySucceeded.isCompleted) {
        _firstRetrySucceeded.complete();
      }
      await _respond(request, HttpStatus.ok, {
        'success': true,
        'data': {'path': request.uri.path},
      });
      return;
    }

    await _respond(request, HttpStatus.unauthorized, {
      'success': false,
      'message': '인증 정보가 없습니다.',
    });
  }

  Future<void> _handleRefresh(HttpRequest request) async {
    refreshRequests++;
    await _bothInitialRequestsFailed.future;

    if (refreshSucceeds) {
      await _respond(request, HttpStatus.ok, {
        'success': true,
        'data': {
          'accessToken': 'rotated-access-token',
          'refreshToken': 'rotated-refresh-token',
        },
      });
      return;
    }

    // 실제 백엔드처럼 사용할 수 없는 refresh token의 회전을 거부한다.
    await _respond(request, HttpStatus.badRequest, {
      'success': false,
      'message': '사용할 수 없는 refreshToken입니다.',
    });
  }

  Future<void> _respond(
    HttpRequest request,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }
}
