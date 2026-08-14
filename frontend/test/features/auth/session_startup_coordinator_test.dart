import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';

void main() {
  test('requires current legal documents before reading session data',
      () async {
    var tokenReads = 0;
    final coordinator = _coordinator(
      hasAcceptedRequiredDocuments: false,
      hasCompletedOnboarding: true,
      refreshToken: 'stored-refresh-token',
      onReadRefreshToken: () => tokenReads++,
    );

    expect(await coordinator.resolveInitialRoute(), '/legal-consent');
    expect(tokenReads, 0);
    expect(
      await coordinator.resolveInitialRouteAfterLegalConsent(),
      '/main/map',
    );
    expect(tokenReads, 1);
  });

  test('restores a stored session before opening an initial push route',
      () async {
    final events = <String>[];
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      hasCompletedOnboarding: () async {
        events.add('read-onboarding');
        return true;
      },
      markOnboardingCompleted: () async {
        events.add('mark-onboarding');
      },
      readRefreshToken: () async {
        events.add('read-refresh-token');
        return 'stored-refresh-token';
      },
      refreshSession: () async {
        events.add('refresh-session');
        return true;
      },
      unregisterPushToken: () async {
        events.add('unregister-push');
      },
      clearLocalTokens: () async {
        events.add('clear-tokens');
      },
      readInitialPushMessage: () async {
        events.add('read-initial-push');
        return const PushMessage(
          title: '쿠폰',
          body: '새 쿠폰이 도착했습니다.',
          data: {'destination': 'COUPONS'},
        );
      },
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/coupons');
    expect(events, [
      'read-onboarding',
      'read-refresh-token',
      'mark-onboarding',
      'refresh-session',
      'read-initial-push',
    ]);
  });

  test('sends a first visit without a refresh token to onboarding', () async {
    var refreshCalls = 0;
    var initialPushCalls = 0;
    final coordinator = _coordinator(
      hasCompletedOnboarding: false,
      refreshToken: null,
      onRefreshSession: () => refreshCalls++,
      onReadInitialPushMessage: () => initialPushCalls++,
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/onboarding');
    expect(refreshCalls, 0);
    expect(initialPushCalls, 0);
  });

  test('sends a returning signed-out user directly to login', () async {
    final coordinator = _coordinator(
      hasCompletedOnboarding: true,
      refreshToken: null,
    );

    expect(await coordinator.resolveInitialRoute(), '/login');
  });

  test('clears local tokens and opens login when session refresh fails',
      () async {
    final events = <String>[];
    final coordinator = _coordinator(
      hasCompletedOnboarding: false,
      refreshToken: 'expired-refresh-token',
      refreshSessionResult: false,
      onUnregisterPushToken: () => events.add('unregister-push'),
      onClearLocalTokens: () => events.add('clear-tokens'),
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/login');
    expect(events, ['unregister-push', 'clear-tokens']);
  });

  test('continues invalid session cleanup when push unregister fails',
      () async {
    var clearCalls = 0;
    final coordinator = _coordinator(
      hasCompletedOnboarding: true,
      refreshToken: 'expired-refresh-token',
      refreshSessionResult: false,
      onUnregisterPushToken: () => throw StateError('push unavailable'),
      onClearLocalTokens: () => clearCalls++,
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/login');
    expect(clearCalls, 1);
  });

  test('coalesces concurrent startup resolution into one refresh', () async {
    var refreshCalls = 0;
    final coordinator = _coordinator(
      hasCompletedOnboarding: true,
      refreshToken: 'stored-refresh-token',
      onRefreshSession: () => refreshCalls++,
    );

    final routes = await Future.wait([
      coordinator.resolveInitialRoute(),
      coordinator.resolveInitialRoute(),
      coordinator.resolveInitialRoute(),
    ]);

    expect(routes, everyElement('/main/map'));
    expect(refreshCalls, 1);
  });

  test('prioritizes a pending Kakao callback over stored session recovery',
      () async {
    var refreshCalls = 0;
    final coordinator = _coordinator(
      hasKakaoAuthorizationCallback: true,
      hasCompletedOnboarding: true,
      refreshToken: 'stored-refresh-token',
      onRefreshSession: () => refreshCalls++,
    );

    expect(await coordinator.resolveInitialRoute(), '/login');
    expect(refreshCalls, 0);
  });
}

SessionStartupCoordinator _coordinator({
  bool hasKakaoAuthorizationCallback = false,
  bool hasAcceptedRequiredDocuments = true,
  required bool hasCompletedOnboarding,
  required String? refreshToken,
  bool refreshSessionResult = true,
  void Function()? onRefreshSession,
  void Function()? onUnregisterPushToken,
  void Function()? onClearLocalTokens,
  void Function()? onReadInitialPushMessage,
  void Function()? onReadRefreshToken,
}) {
  return SessionStartupCoordinator(
    hasKakaoAuthorizationCallback: hasKakaoAuthorizationCallback,
    hasAcceptedRequiredDocuments: () async => hasAcceptedRequiredDocuments,
    hasCompletedOnboarding: () async => hasCompletedOnboarding,
    markOnboardingCompleted: () async {},
    readRefreshToken: () async {
      onReadRefreshToken?.call();
      return refreshToken;
    },
    refreshSession: () async {
      onRefreshSession?.call();
      return refreshSessionResult;
    },
    unregisterPushToken: () async {
      onUnregisterPushToken?.call();
    },
    clearLocalTokens: () async {
      onClearLocalTokens?.call();
    },
    readInitialPushMessage: () async {
      onReadInitialPushMessage?.call();
      return null;
    },
  );
}
