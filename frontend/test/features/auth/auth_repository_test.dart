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
