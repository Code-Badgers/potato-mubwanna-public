import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/session_startup_screen.dart';

void main() {
  testWidgets('shows the onboarding image while resolving startup route',
      (tester) async {
    final refreshTokenCompleter = Completer<String?>();
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      hasCompletedOnboarding: () async => true,
      markOnboardingCompleted: () async {},
      readRefreshToken: () => refreshTokenCompleter.future,
      refreshSession: () async => false,
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
    expect(find.byKey(const Key('session-startup-progress')), findsOneWidget);

    refreshTokenCompleter.complete(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-route')), findsOneWidget);
  });
}
