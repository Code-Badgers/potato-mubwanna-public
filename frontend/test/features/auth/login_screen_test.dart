import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/login_screen.dart';
import 'package:potato_mubwanna/features/onboarding/data/onboarding_status_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('renders kakao login entry points', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.bySemanticsLabel('카카오 로그인'), findsWidgets);
    expect(find.text('Apple 로그인 준비 중'), findsNothing);
    expect(find.text('나중에 로그인하기'), findsOneWidget);
  });

  testWidgets('uses the button material for the kakao ink response', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFFFEE500),
    );
  });

  for (final width in [430.0, 1200.0]) {
    testWidgets(
      'keeps the kakao button at its source ratio on ${width.toInt()}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginScreen())),
        );

        final buttonContent = find.byKey(
          const Key('kakao-login-button-content'),
        );
        final buttonSize = tester.getSize(buttonContent);
        expect(buttonSize.width, 300);
        expect(buttonSize.height, 45);
        expect(buttonSize.aspectRatio, closeTo(300 / 45, 0.01));
        expect(find.byType(Image), findsNothing);
      },
    );
  }

  testWidgets('shows unsupported message when kakao login cannot start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthController(
                kakaoLoginService: _UnsupportedKakaoLoginService(),
                authRepository: _NoopAuthRepository(),
              ),
            ),
          ],
          child: const LoginScreen(),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('카카오 로그인').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.'), findsOneWidget);
  });

  testWidgets('records onboarding completion when continuing as a guest', (
    tester,
  ) async {
    final statusStore = _RecordingOnboardingStatusStore();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/permissions',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('permissions destination')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusStoreProvider.overrideWithValue(statusStore),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('나중에 로그인하기'));
    await tester.pumpAndSettle();

    expect(statusStore.markCalls, 1);
    expect(find.text('permissions destination'), findsOneWidget);
  });
}

class _UnsupportedKakaoLoginService extends KakaoLoginService {
  @override
  Future<KakaoLoginResult> login() {
    throw const KakaoLoginUnsupportedException(
      '테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.',
    );
  }
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository()
    : super(
        dio: Dio(),
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      );

  @override
  Future<void> loginWithKakaoToken(String kakaoAccessToken) async {}
}

class _RecordingOnboardingStatusStore implements OnboardingStatusStore {
  int markCalls = 0;

  @override
  Future<bool> hasCompletedOnboarding() async => false;

  @override
  Future<void> markOnboardingCompleted() async {
    markCalls++;
  }
}
