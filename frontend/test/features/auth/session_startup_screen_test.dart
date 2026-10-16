import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/session_startup_screen.dart';

void main() {
  testWidgets('waits on the onboarding image until the user taps to continue',
      (tester) async {
    final refreshTokenCompleter = Completer<String?>();
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      markOnboardingCompleted: () async {},
      readRefreshToken: () => refreshTokenCompleter.future,
      refreshSession: () async => false,
      unregisterPushToken: () async {},
      clearLocalTokens: () async {},
      readInitialPushMessage: () async => null,
    );
    final router = GoRouter(
      initialLocation: '/startup',
      routes: [
        GoRoute(
          path: '/startup',
          builder: (_, __) => const SessionStartupScreen(),
        ),
        GoRoute(
          path: '/startup/loading',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: SessionStartupLoadingScreen(),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const SizedBox(key: Key('onboarding-route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStartupCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(
        find.byKey(const Key('session-startup-brand-image')), findsOneWidget);
    expect(find.text('터치하여 시작하기'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('onboarding-route')), findsNothing);

    await tester.tap(find.byKey(const Key('session-startup-brand-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byKey(const Key('session-startup-loading')), findsOneWidget);
    expect(find.text('여행을 준비하고 있어요'), findsOneWidget);
    expect(find.text('터치하여 시작하기'), findsNothing);
    expect(find.byKey(const Key('session-startup-brand-image')), findsNothing);

    refreshTokenCompleter.complete(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-route')), findsOneWidget);
  });

  testWidgets('shows retry without signing out and blocks duplicate retry taps',
      (tester) async {
    var refreshCalls = 0;
    var clearCalls = 0;
    final retry = Completer<bool>();
    final coordinator = _retryCoordinator(
      refreshSession: () {
        if (++refreshCalls == 1) throw TimeoutException('offline');
        return retry.future;
      },
      onClearTokens: () => clearCalls++,
      initialMessage: const PushMessage(
          title: null, body: null, data: {'destination': 'COUPONS'}),
    );
    await _pumpLoadingScreen(tester, coordinator);
    await tester.pumpAndSettle();
    expect(find.text('로그인 상태를 확인하지 못했어요'), findsOneWidget);
    expect(find.textContaining('저장된 로그인 정보는 그대로 유지돼요.'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-route')), findsNothing);
    expect(clearCalls, 0);

    await tester.tap(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(refreshCalls, 2);
    expect(find.text('여행을 준비하고 있어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
    retry.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coupons-route')), findsOneWidget);
    expect(clearCalls, 0);
  });

  for (final size in [const Size(320, 568), const Size(1280, 900)]) {
    testWidgets('retry screen fits $size with large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final coordinator = _retryCoordinator(
        refreshSession: () async => throw TimeoutException('offline'),
      );
      await _pumpLoadingScreen(tester, coordinator, textScaleFactor: 2);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('다시 시도'));
      expect(tester.takeException(), isNull);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  }
}

SessionStartupCoordinator _retryCoordinator({
  required Future<bool> Function() refreshSession,
  void Function()? onClearTokens,
  PushMessage? initialMessage,
}) {
  return SessionStartupCoordinator(
    hasKakaoAuthorizationCallback: false,
    markOnboardingCompleted: () async {},
    readRefreshToken: () async => 'stored-refresh-token',
    refreshSession: refreshSession,
    unregisterPushToken: () async {},
    clearLocalTokens: () async => onClearTokens?.call(),
    readInitialPushMessage: () async => initialMessage,
  );
}

Future<void> _pumpLoadingScreen(
    WidgetTester tester, SessionStartupCoordinator coordinator,
    {double textScaleFactor = 1}) async {
  final router = GoRouter(
    initialLocation: '/startup/loading',
    routes: [
      GoRoute(
          path: '/startup/loading',
          builder: (_, __) => const SessionStartupLoadingScreen()),
      GoRoute(
          path: '/main/map',
          builder: (_, __) => const SizedBox(key: Key('map-route'))),
      GoRoute(
          path: '/coupons',
          builder: (_, __) => const SizedBox(key: Key('coupons-route'))),
      GoRoute(
          path: '/onboarding',
          builder: (_, __) => const SizedBox(key: Key('onboarding-route'))),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sessionStartupCoordinatorProvider.overrideWithValue(coordinator),
      authControllerProvider.overrideWith((ref) => AuthController(
            kakaoLoginService: const KakaoLoginService(),
            authRepository: AuthRepository(
                dio: Dio(),
                tokenStorage: const TokenStorage(FlutterSecureStorage())),
          )),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
        child: child!,
      ),
    ),
  ));
}
