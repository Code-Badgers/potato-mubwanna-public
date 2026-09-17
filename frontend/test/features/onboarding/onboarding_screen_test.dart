import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/core/permissions/permission_service.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/onboarding/data/onboarding_status_store.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/onboarding_screen.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/permission_guide_screen.dart';

void main() {
  testWidgets('walks through service intro onboarding pages', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );

    expect(find.byType(Image), findsWidgets);
    expect(find.text('다음'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-430, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('다음'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-430, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('다음'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-430, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('카카오 로그인'), findsOneWidget);
  });

  testWidgets('intro copy remains readable by assistive technology', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );

    expect(
      find.bySemanticsLabel(
        '강원도 여행을 더 특별하게. 지도에서 여행지를 찾고 감자 친구와 함께 여행을 시작해보세요.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('1/4 페이지'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('intro pages fit common phone widths', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in <Size>[
      const Size(360, 780),
      const Size(375, 812),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'phone width ${size.width}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('shows only the runtime permissions currently used', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PermissionGuideScreen()));

    expect(find.text('편리한 감자여행을 위해\n접근권한을 확인해주세요'), findsOneWidget);
    expect(find.text('알림 [선택]'), findsOneWidget);
    expect(find.text('위치 [선택]'), findsOneWidget);
    expect(find.text('카메라 [선택]'), findsNothing);
    expect(find.text('사진 및 동영상 [선택]'), findsNothing);
    expect(find.text('닉네임 [필수]'), findsNothing);
    expect(find.text('이메일 [선택]'), findsNothing);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('starts kakao login directly from the last onboarding page', (
    tester,
  ) async {
    final statusStore = _RecordingOnboardingStatusStore();
    final kakaoService = _RecordingKakaoLoginService();
    final authRepository = _RecordingAuthRepository();
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => OnboardingScreen(
            onboardingStatusStore: statusStore,
            initialPage: 3,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('login destination'))),
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
    await tester.tap(find.text('카카오 로그인'));
    await tester.pumpAndSettle();

    expect(statusStore.markCalls, 1);
    expect(kakaoService.loginCalls, 1);
    expect(authRepository.accessToken, 'test-access-token');
    expect(find.text('permissions destination'), findsOneWidget);
    expect(find.text('login destination'), findsNothing);
  });

  testWidgets('shows kakao login failure on the last onboarding page', (
    tester,
  ) async {
    final kakaoService = _RecordingKakaoLoginService(shouldFail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              kakaoLoginService: kakaoService,
              authRepository: _RecordingAuthRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          home: OnboardingScreen(
            initialPage: 3,
            onboardingStatusStore: _RecordingOnboardingStatusStore(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('카카오 로그인'));
    await tester.pumpAndSettle();

    expect(kakaoService.loginCalls, 1);
    expect(find.text('테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.'), findsOneWidget);
    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.text('감자 여행을 시작해볼까요?'), findsNothing);
  });

  testWidgets('disables the kakao button while saving onboarding status',
      (tester) async {
    final statusStore = _BlockingOnboardingStatusStore();
    final kakaoService = _RecordingKakaoLoginService(shouldFail: true);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => AuthController(
            kakaoLoginService: kakaoService,
            authRepository: _RecordingAuthRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        home: OnboardingScreen(
          initialPage: 3,
          onboardingStatusStore: statusStore,
        ),
      ),
    ));

    await tester.tap(find.text('카카오 로그인'));
    await tester.pump();
    expect(statusStore.markCalls, 1);
    expect(kakaoService.loginCalls, 0);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    statusStore.complete();
    await tester.pumpAndSettle();
    expect(kakaoService.loginCalls, 1);
    expect(find.text('카카오 로그인'), findsOneWidget);
  });

  testWidgets('requests location and enters the map when granted', (
    tester,
  ) async {
    final permissionService = _FakePermissionService(
      requestResult: PermissionStatus.granted,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 1);
    expect(permissionService.notificationRequestCalls, 1);
    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('explains denial before allowing entry without permission', (
    tester,
  ) async {
    final permissionService = _FakePermissionService(
      requestResult: PermissionStatus.denied,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 1);
    expect(permissionService.notificationRequestCalls, 1);
    expect(
      find.text('위치 권한 없이 둘러볼 수 있지만 주변 탐색과 방문 인증은 제한됩니다.'),
      findsOneWidget,
    );
    expect(find.text('권한 없이 둘러보기'), findsOneWidget);
    expect(find.text('map destination'), findsNothing);

    await tester.tap(find.text('권한 없이 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('does not request runtime permission on the web', (tester) async {
    final permissionService = _FakePermissionService(
      supportsRuntimePermissions: false,
      requestResult: PermissionStatus.denied,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('웹에서는 브라우저 설정에서 위치와 알림 권한을 관리해주세요.'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 0);
    expect(permissionService.notificationRequestCalls, 0);
    expect(find.text('map destination'), findsOneWidget);
  });
}

GoRouter _permissionRouter(PermissionService permissionService) {
  return GoRouter(
    initialLocation: '/permissions',
    routes: [
      GoRoute(
        path: '/permissions',
        builder: (_, __) => PermissionGuideScreen(
          permissionService: permissionService,
          legalConsentStore: _AcceptedLegalConsentStore(),
        ),
      ),
      GoRoute(
        path: '/main/map',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('map destination'))),
      ),
    ],
  );
}

class _AcceptedLegalConsentStore implements LegalConsentStore {
  @override
  Future<void> acceptRequiredDocuments() async {}

  @override
  Future<bool> hasAcceptedHealthData() async => true;

  @override
  Future<bool> hasAcceptedPersonalLocation() async => true;

  @override
  Future<bool> hasAcceptedRequiredDocuments() async => true;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {}

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {}
}

class _FakePermissionService extends PermissionService {
  _FakePermissionService({
    this.supportsRuntimePermissions = true,
    required this.requestResult,
  });

  @override
  final bool supportsRuntimePermissions;

  final PermissionStatus requestResult;
  int locationRequestCalls = 0;
  int notificationRequestCalls = 0;

  @override
  Future<PermissionStatus> requestLocation() async {
    locationRequestCalls++;
    return requestResult;
  }

  @override
  Future<PermissionStatus> requestNotification() async {
    notificationRequestCalls++;
    return requestResult;
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

class _BlockingOnboardingStatusStore extends _RecordingOnboardingStatusStore {
  final Completer<void> _completion = Completer<void>();

  @override
  Future<void> markOnboardingCompleted() async {
    markCalls++;
    await _completion.future;
  }

  void complete() => _completion.complete();
}

class _RecordingKakaoLoginService extends KakaoLoginService {
  _RecordingKakaoLoginService({this.shouldFail = false});

  final bool shouldFail;
  int loginCalls = 0;

  @override
  Future<KakaoLoginResult> login() async {
    loginCalls++;
    if (shouldFail) {
      throw const KakaoLoginUnsupportedException(
        '테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.',
      );
    }
    return const KakaoAccessTokenLoginResult('test-access-token');
  }
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  String? accessToken;

  @override
  Future<void> loginWithKakaoToken(String kakaoAccessToken) async {
    accessToken = kakaoAccessToken;
  }
}
