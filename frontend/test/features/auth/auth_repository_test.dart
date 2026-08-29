import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
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
        'data': {'accessToken': '', 'refreshToken': ''},
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

  test('maps backend login rejection without exposing request tokens',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException.badResponse(
                statusCode: 401,
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'success': false,
                    'message': '인증이 필요합니다.',
                    'code': 'AUTH_REQUIRED',
                    'data': null,
                  },
                ),
              ),
            );
          },
        ),
      );

    await expectLater(
      AuthRepository(
        dio: dio,
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      ).loginWithKakaoToken('sensitive-kakao-access-token'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.code, 'code', 'AUTH_REQUIRED')
            .having((error) => error.message, 'message', '인증이 필요합니다.')
            .having(
              (error) => error.toString(),
              'serialized error',
              isNot(contains('sensitive-kakao-access-token')),
            ),
      ),
    );
  });

  test(
    'sends web authorization code to the backend exchange endpoint',
    () async {
      String? requestedPath;
      Object? requestedData;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedPath = options.path;
              requestedData = options.data;
              handler.resolve(
                Response<Map<String, Object?>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': '요청이 성공했습니다.',
                    'data': {
                      'accessToken': 'jwt-access-token',
                      'refreshToken': 'jwt-refresh-token',
                    },
                  },
                ),
              );
            },
          ),
        );

      await AuthRepository(
        dio: dio,
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      ).loginWithKakaoAuthorizationCode(
        authorizationCode: 'authorization-code',
        redirectUri: 'http://localhost:54631/',
      );

      expect(requestedPath, '/auth/kakao/code');
      expect(requestedData, {
        'authorizationCode': 'authorization-code',
        'redirectUri': 'http://localhost:54631/',
      });
    },
  );

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

    await AuthRepository(dio: dio, tokenStorage: tokenStorage).refreshSession();

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
                data: {'success': true, 'message': '요청이 성공했습니다.', 'data': null},
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

    await AuthRepository(dio: dio, tokenStorage: tokenStorage).logout();

    expect(requestedPaths, contains('/auth/logout'));
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
  });

  test('withdraws account and clears local tokens after success', () async {
    final requestedMethods = <String>[];
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedMethods.add(options.method);
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
    ).withdrawAccount();

    expect(requestedMethods, ['DELETE']);
    expect(requestedPaths, ['/users/me']);
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
  });

  test('keeps local tokens when account withdrawal fails', () async {
    final dio = _dioWithResponse(
      data: {
        'success': false,
        'message': '회원 탈퇴에 실패했습니다.',
        'data': null,
      },
    );
    const tokenStorage = TokenStorage(FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'jwt-access-token',
      refreshToken: 'jwt-refresh-token',
    );

    await expectLater(
      AuthRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      ).withdrawAccount(),
      throwsA(isA<Exception>()),
    );

    expect(await tokenStorage.readAccessToken(), 'jwt-access-token');
    expect(await tokenStorage.readRefreshToken(), 'jwt-refresh-token');
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
