import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/auth/application/session_startup_coordinator.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';

void main() {
  test('requires current legal documents before reading session data',
      () async {
    var tokenReads = 0;
    final coordinator = _coordinator(
      hasAcceptedRequiredDocuments: false,
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

  test('shows required consent before onboarding for a signed-out user',
      () async {
    final coordinator = _coordinator(
      hasAcceptedRequiredDocuments: false,
      refreshToken: null,
    );

    expect(await coordinator.resolveInitialRoute(), '/legal-consent');
    expect(
      await coordinator.resolveInitialRouteAfterLegalConsent(),
      '/onboarding',
    );
  });

  test('restores a stored session before opening an initial push route',
      () async {
    final events = <String>[];
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
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

    expect(route, '/coupons', reason: events.toString());
    expect(events, [
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
      refreshToken: null,
      onRefreshSession: () => refreshCalls++,
      onReadInitialPushMessage: () => initialPushCalls++,
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/onboarding');
    expect(refreshCalls, 0);
    expect(initialPushCalls, 0);
  });

  test('waits for the stored token before choosing onboarding', () async {
    final refreshToken = Completer<String?>();
    var refreshTokenReads = 0;
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      markOnboardingCompleted: () async {},
      readRefreshToken: () {
        refreshTokenReads++;
        return refreshToken.future;
      },
      refreshSession: () async => false,
      unregisterPushToken: () async {},
      clearLocalTokens: () async {},
      readInitialPushMessage: () async => null,
    );

    final route = coordinator.resolveInitialRoute();
    await Future<void>.delayed(Duration.zero);

    expect(refreshTokenReads, 1);

    refreshToken.complete(null);
    expect(await route, '/onboarding');
  });

  test('does not hold startup when initial push lookup times out', () async {
    final initialMessage = Completer<PushMessage?>();
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      markOnboardingCompleted: () async {},
      readRefreshToken: () async => 'stored-refresh-token',
      refreshSession: () async => true,
      unregisterPushToken: () async {},
      clearLocalTokens: () async {},
      readInitialPushMessage: () => initialMessage.future,
      initialMessageTimeout: const Duration(milliseconds: 1),
    );

    expect(await coordinator.resolveInitialRoute(), '/main/map');
  });

  test('sends a returning signed-out user to onboarding', () async {
    final coordinator = _coordinator(
      refreshToken: null,
    );

    expect(await coordinator.resolveInitialRoute(), '/onboarding');
  });

  test('clears local tokens and opens onboarding when session refresh fails',
      () async {
    final events = <String>[];
    final coordinator = _coordinator(
      refreshToken: 'expired-refresh-token',
      refreshSessionResult: false,
      onUnregisterPushToken: () => events.add('unregister-push'),
      onClearLocalTokens: () => events.add('clear-tokens'),
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/onboarding');
    expect(events, ['unregister-push', 'clear-tokens']);
  });

  test('continues invalid session cleanup when push unregister fails',
      () async {
    var clearCalls = 0;
    final coordinator = _coordinator(
      refreshToken: 'expired-refresh-token',
      refreshSessionResult: false,
      onUnregisterPushToken: () => throw StateError('push unavailable'),
      onClearLocalTokens: () => clearCalls++,
    );

    final route = await coordinator.resolveInitialRoute();

    expect(route, '/onboarding');
    expect(clearCalls, 1);
  });

  test('coalesces concurrent startup resolution into one refresh', () async {
    var refreshCalls = 0;
    final coordinator = _coordinator(
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

  test('keeps tokens and the initial push untouched until a retry succeeds',
      () async {
    var refreshCalls = 0;
    var clearCalls = 0;
    var unregisterCalls = 0;
    var pushReads = 0;
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      markOnboardingCompleted: () async {},
      readRefreshToken: () async => 'stored-refresh-token',
      refreshSession: () async {
        if (++refreshCalls == 1) throw TimeoutException('connection lost');
        return true;
      },
      unregisterPushToken: () async => unregisterCalls++,
      clearLocalTokens: () async => clearCalls++,
      readInitialPushMessage: () async {
        pushReads++;
        return const PushMessage(
            title: null,
            body: null,
            data: {'destination': 'SPOT', 'destinationId': '7'});
      },
    );

    await expectLater(coordinator.resolveInitialRoute(),
        throwsA(isA<SessionStartupFailure>()));
    expect(clearCalls, 0);
    expect(unregisterCalls, 0);
    expect(pushReads, 0);
    expect(await coordinator.resolveInitialRoute(), '/spots/7');
    expect(await coordinator.resolveInitialRoute(), '/spots/7');
    expect(refreshCalls, 2);
    expect(pushReads, 1);
  });

  test('coalesces retry requests after a failed attempt', () async {
    final retry = Completer<bool>();
    var refreshCalls = 0;
    final coordinator = _coordinator(
      refreshToken: 'stored-refresh-token',
      refreshSession: () {
        if (++refreshCalls == 1) throw const ApiException(message: 'offline');
        return retry.future;
      },
    );
    await expectLater(coordinator.resolveInitialRoute(),
        throwsA(isA<SessionStartupFailure>()));
    final first = coordinator.resolveInitialRoute();
    final second = coordinator.resolveInitialRoute();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(refreshCalls, 2);
    retry.complete(true);
    expect(await first, '/main/map');
    expect(await second, '/main/map');
  });

  test('repeated transient failures never clear tokens or unregister push',
      () async {
    var clearCalls = 0;
    var unregisterCalls = 0;
    final coordinator = _coordinator(
      refreshToken: 'stored-refresh-token',
      refreshSession: () async =>
          throw const ApiException(message: 'unavailable', statusCode: 503),
      onClearLocalTokens: () => clearCalls++,
      onUnregisterPushToken: () => unregisterCalls++,
    );
    for (var attempt = 0; attempt < 3; attempt++) {
      await expectLater(coordinator.resolveInitialRoute(),
          throwsA(isA<SessionStartupFailure>()));
    }
    expect(clearCalls, 0);
    expect(unregisterCalls, 0);
  });

  test('does not mistake a token storage failure for a signed-out user',
      () async {
    var tokenReads = 0;
    var clearCalls = 0;
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      markOnboardingCompleted: () async {},
      readRefreshToken: () async {
        if (++tokenReads == 1) throw StateError('storage unavailable');
        return 'stored-refresh-token';
      },
      refreshSession: () async => true,
      unregisterPushToken: () async {},
      clearLocalTokens: () async => clearCalls++,
      readInitialPushMessage: () async => null,
    );
    await expectLater(coordinator.resolveInitialRoute(),
        throwsA(isA<SessionStartupFailure>()));
    expect(await coordinator.resolveInitialRoute(), '/main/map');
    expect(clearCalls, 0);
  });

  test('preserves accepted consent when session recovery needs a retry',
      () async {
    var consentReads = 0;
    var refreshCalls = 0;
    final coordinator = SessionStartupCoordinator(
      hasKakaoAuthorizationCallback: false,
      hasAcceptedRequiredDocuments: () async {
        consentReads++;
        return false;
      },
      markOnboardingCompleted: () async {},
      readRefreshToken: () async => 'stored-refresh-token',
      refreshSession: () async {
        if (++refreshCalls == 1) throw TimeoutException('offline');
        return true;
      },
      unregisterPushToken: () async {},
      clearLocalTokens: () async {},
      readInitialPushMessage: () async => null,
    );
    expect(await coordinator.resolveInitialRoute(), '/legal-consent');
    await expectLater(coordinator.resolveInitialRouteAfterLegalConsent(),
        throwsA(isA<SessionStartupFailure>()));
    expect(await coordinator.resolveInitialRoute(), '/main/map');
    expect(consentReads, 1);
  });

  test('prioritizes a pending Kakao callback over stored session recovery',
      () async {
    var refreshCalls = 0;
    final coordinator = _coordinator(
      hasKakaoAuthorizationCallback: true,
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
  required String? refreshToken,
  bool refreshSessionResult = true,
  Future<bool> Function()? refreshSession,
  void Function()? onRefreshSession,
  void Function()? onUnregisterPushToken,
  void Function()? onClearLocalTokens,
  void Function()? onReadInitialPushMessage,
  void Function()? onReadRefreshToken,
}) {
  return SessionStartupCoordinator(
    hasKakaoAuthorizationCallback: hasKakaoAuthorizationCallback,
    hasAcceptedRequiredDocuments: () async => hasAcceptedRequiredDocuments,
    markOnboardingCompleted: () async {},
    readRefreshToken: () async {
      onReadRefreshToken?.call();
      return refreshToken;
    },
    refreshSession: () async {
      onRefreshSession?.call();
      return refreshSession == null
          ? refreshSessionResult
          : await refreshSession();
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
