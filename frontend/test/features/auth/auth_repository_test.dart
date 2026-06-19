import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('saves backend jwt tokens after kakao login succeeds', () async {
    final dio = _dioWithResponse(
      data: {
        'success': true,
        'message': '요청이 성공했습니다.',
        'data': {
          'accessToken': 'jwt-access-token',
          'refreshToken': 'jwt-refresh-token',
        },
      },
    );
    const tokenStorage = TokenStorage(FlutterSecureStorage());

    await AuthRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    ).loginWithKakaoToken('kakao-access-token');

    expect(await tokenStorage.readAccessToken(), 'jwt-access-token');
    expect(await tokenStorage.readRefreshToken(), 'jwt-refresh-token');
  });

  test('throws when backend token payload is missing', () async {
    final dio = _dioWithResponse(
      data: {
        'success': true,
        'message': '요청이 성공했습니다.',
        'data': {
          'accessToken': '',
          'refreshToken': '',
        },
      },
    );

    expect(
      () => AuthRepository(
        dio: dio,
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      ).loginWithKakaoToken('kakao-access-token'),
      throwsA(isA<Exception>()),
    );
  });

  test('refreshes stored backend jwt tokens', () async {
    final dio = _dioWithResponse(
      data: {
        'success': true,
        'message': '요청이 성공했습니다.',
        'data': {
          'accessToken': 'new-jwt-access-token',
          'refreshToken': 'new-jwt-refresh-token',
        },
      },
    );
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'old-jwt-access-token',
      refreshToken: 'old-jwt-refresh-token',
    );

    await AuthRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    ).refreshSession();

    expect(await tokenStorage.readAccessToken(), 'new-jwt-access-token');
    expect(await tokenStorage.readRefreshToken(), 'new-jwt-refresh-token');
  });

  test('logout revokes backend session and clears local tokens', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '요청이 성공했습니다.',
                  'data': null,
                },
              ),
            );
          },
        ),
      );
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'jwt-access-token',
      refreshToken: 'jwt-refresh-token',
    );

    await AuthRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    ).logout();

    expect(requestedPaths, contains('/auth/logout'));
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
  });
}

Dio _dioWithResponse({required Map<String, Object?> data}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, Object?>>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
}
