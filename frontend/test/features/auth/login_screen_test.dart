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

  testWidgets(
    'login route shows the onboarding kakao action without an extra screen',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.bySemanticsLabel('4/4 페이지'), findsOneWidget);
      expect(find.text('감자 여행을 시작해볼까요?'), findsNothing);
      expect(find.text('나중에 로그인하기'), findsNothing);
    },
  );

  testWidgets('web authorization callback still enters permissions', (
    tester,
  ) async {
    final kakaoService = _CallbackKakaoLoginService();
    final authRepository = _RecordingAuthRepository();
    final statusStore = _RecordingOnboardingStatusStore();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
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
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              kakaoLoginService: kakaoService,
              authRepository: authRepository,
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(authRepository.authorizationCode, 'authorization-code');
    expect(kakaoService.cleared, isTrue);
    expect(statusStore.markCalls, 1);
    expect(find.text('permissions destination'), findsOneWidget);
  });

  testWidgets('failed web callback stays on the onboarding kakao action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              kakaoLoginService: _RejectedCallbackKakaoLoginService(),
              authRepository: _RecordingAuthRepository(),
            ),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('카카오 로그인이 취소되었습니다.'), findsOneWidget);
    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.text('감자 여행을 시작해볼까요?'), findsNothing);
  });
}

class _CallbackKakaoLoginService extends KakaoLoginService {
  bool cleared = false;

  @override
  KakaoAuthorizationCallback? readAuthorizationCallback() {
    return const KakaoAuthorizationCallback(
      authorizationCode: 'authorization-code',
      redirectUri: 'http://localhost:54631/',
    );
  }

  @override
  void clearAuthorizationCallback() {
    cleared = true;
  }
}

class _RejectedCallbackKakaoLoginService extends KakaoLoginService {
  @override
  KakaoAuthorizationCallback? readAuthorizationCallback() {
    throw const KakaoLoginUnsupportedException('카카오 로그인이 취소되었습니다.');
  }
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository()
    : super(
        dio: Dio(),
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      );

  String? authorizationCode;

  @override
  Future<void> loginWithKakaoAuthorizationCode({
    required String authorizationCode,
    required String redirectUri,
  }) async {
    this.authorizationCode = authorizationCode;
  }
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
