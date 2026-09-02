import 'dart:async';

import 'package:flutter/material.dart';
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
      hasCompletedOnboarding: () async => true,
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
          path: '/login',
          builder: (_, __) => const SizedBox(key: Key('login-route')),
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
    expect(find.byKey(const Key('login-route')), findsNothing);

    await tester.tap(find.byKey(const Key('session-startup-brand-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byKey(const Key('session-startup-loading')), findsOneWidget);
    expect(find.text('여행을 준비하고 있어요'), findsOneWidget);
    expect(find.text('터치하여 시작하기'), findsNothing);
    expect(
        find.byKey(const Key('session-startup-brand-image')), findsNothing);

    refreshTokenCompleter.complete(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-route')), findsOneWidget);
  });
}
