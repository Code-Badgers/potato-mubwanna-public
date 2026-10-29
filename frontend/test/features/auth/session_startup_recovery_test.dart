import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/login_screen.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/session_startup_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
        'expired startup guides re-login and recovers the session at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      const storage = TokenStorage(FlutterSecureStorage());
      await storage.saveTokens(
          accessToken: 'old-access', refreshToken: 'old-refresh');
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
      addTearDown(dio.close);
      var refreshCalls = 0;
      var loginCalls = 0;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path == '/auth/refresh') {
          refreshCalls++;
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
                requestOptions: options,
                statusCode: 401,
                data: <String, dynamic>{
                  'success': false,
                  'message': '로그인 세션이 만료되었습니다. 다시 로그인해주세요.',
                  'data': null
                }),
          ));
        } else {
          expect(options.path, '/auth/kakao');
          expect(options.data, {'accessToken': 'kakao-test-token'});
          loginCalls++;
          handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': {
                  'accessToken': 'new-access',
                  'refreshToken': 'new-refresh'
                }
              }));
        }
      }));
      final controller = AuthController(
        kakaoLoginService: const _SuccessfulKakaoLoginService(),
        authRepository: AuthRepository(dio: dio, tokenStorage: storage),
      );
      final events = <String>[];
      final coordinator = SessionStartupCoordinator(
        hasKakaoAuthorizationCallback: false,
        markOnboardingCompleted: () async {},
        readRefreshToken: storage.readRefreshToken,
        refreshSession: controller.refreshSession,
        unregisterPushToken: () async {
          expect(await storage.readRefreshToken(), 'old-refresh');
          events.add('unregister');
        },
        clearLocalTokens: () async {
          events.add('clear');
          await storage.clearTokens();
        },
        readInitialPushMessage: () async => null,
      );
      final router = GoRouter(initialLocation: '/startup/loading', routes: [
        GoRoute(
            path: '/startup/loading',
            builder: (_, __) => const SessionStartupLoadingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: '/permissions',
            builder: (_, __) => const Scaffold(body: Text('permissions'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => controller),
            sessionStartupCoordinatorProvider.overrideWithValue(coordinator),
          ],
          child:
              MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
      await tester.pumpAndSettle();
      expect(router.location, '/login');
      expect(find.text('로그인 세션이 만료되었습니다. 다시 로그인해주세요.'), findsOneWidget);
      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.bySemanticsLabel('4/4 페이지'), findsOneWidget);
      expect(events, ['unregister', 'clear']);
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(refreshCalls, 1);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('카카오 로그인'));
      await tester.pumpAndSettle();
      expect(router.location, '/permissions');
      expect(loginCalls, 1);
      expect(await storage.readAccessToken(), 'new-access');
      expect(await storage.readRefreshToken(), 'new-refresh');
      expect(controller.state.status, AuthStatus.authenticated);
      expect(tester.takeException(), isNull);
    });
  }
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
        expect(await coordinator.resolveInitialRoute(), '/login');
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

class _SuccessfulKakaoLoginService extends KakaoLoginService {
  const _SuccessfulKakaoLoginService();

  @override
  Future<KakaoLoginResult> login() async =>
      const KakaoAccessTokenLoginResult('kakao-test-token');
}
