import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';

void main() {
  for (final status in [null, 401, 503]) {
    test('startup preserves or clears real stored tokens for status $status',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = TokenStorage(FlutterSecureStorage());
      await storage.saveTokens(
          accessToken: 'old-access', refreshToken: 'old-refresh');
      var requests = 0;
      var unregisterCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.data, {'refreshToken': 'old-refresh'});
        if (++requests == 1) {
          handler.reject(DioException(
            requestOptions: options,
            type: status == null
                ? DioExceptionType.connectionTimeout
                : DioExceptionType.badResponse,
            response: status == null
                ? null
                : Response(
                    requestOptions: options,
                    statusCode: status,
                    data: <String, dynamic>{
                      'success': false,
                      'message': 'unavailable',
                      'data': null
                    },
                  ),
          ));
        } else {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'message': 'ok',
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
              }
            },
          ));
        }
      }));
      final controller = AuthController(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: AuthRepository(dio: dio, tokenStorage: storage));
      addTearDown(controller.dispose);
      final coordinator = SessionStartupCoordinator(
        hasKakaoAuthorizationCallback: false,
        markOnboardingCompleted: () async {},
        readRefreshToken: storage.readRefreshToken,
        refreshSession: controller.refreshSession,
        unregisterPushToken: () async => unregisterCalls++,
        clearLocalTokens: storage.clearTokens,
        readInitialPushMessage: () async => null,
      );
      if (status == 401) {
        expect(await coordinator.resolveInitialRoute(), '/onboarding');
        expect(await storage.readAccessToken(), isNull);
        expect(await storage.readRefreshToken(), isNull);
        expect(unregisterCalls, 1);
      } else {
        await expectLater(coordinator.resolveInitialRoute(),
            throwsA(isA<SessionStartupFailure>()));
        expect(await storage.readAccessToken(), 'old-access');
        expect(await storage.readRefreshToken(), 'old-refresh');
        expect(unregisterCalls, 0);
        expect(await coordinator.resolveInitialRoute(), '/main/map');
        expect(controller.state.status, AuthStatus.authenticated);
        expect(await storage.readAccessToken(), 'new-access');
        expect(await storage.readRefreshToken(), 'new-refresh');
      }
    });
  }
}
