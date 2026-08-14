import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_environment.dart';
import '../../onboarding/data/onboarding_status_store.dart';
import '../../legal/data/legal_consent_store.dart';
import '../../push/domain/push_message.dart';
import 'auth_controller.dart';

final sessionStartupCoordinatorProvider =
    Provider<SessionStartupCoordinator>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final onboardingStatusStore = ref.watch(onboardingStatusStoreProvider);
  final legalConsentStore = ref.watch(legalConsentStoreProvider);
  final pushNotificationService = ref.watch(pushNotificationServiceProvider);

  return SessionStartupCoordinator(
    hasKakaoAuthorizationCallback: AppEnvironment.hasKakaoAuthorizationCallback,
    hasAcceptedRequiredDocuments:
        legalConsentStore.hasAcceptedRequiredDocuments,
    hasCompletedOnboarding: onboardingStatusStore.hasCompletedOnboarding,
    markOnboardingCompleted: onboardingStatusStore.markOnboardingCompleted,
    readRefreshToken: tokenStorage.readRefreshToken,
    refreshSession: ref.watch(authControllerProvider.notifier).refreshSession,
    unregisterPushToken: pushNotificationService.unregister,
    clearLocalTokens: tokenStorage.clearTokens,
    readInitialPushMessage: pushNotificationService.getInitialMessage,
  );
});

class SessionStartupCoordinator {
  SessionStartupCoordinator({
    required bool hasKakaoAuthorizationCallback,
    Future<bool> Function()? hasAcceptedRequiredDocuments,
    required Future<bool> Function() hasCompletedOnboarding,
    required Future<void> Function() markOnboardingCompleted,
    required Future<String?> Function() readRefreshToken,
    required Future<bool> Function() refreshSession,
    required Future<void> Function() unregisterPushToken,
    required Future<void> Function() clearLocalTokens,
    required Future<PushMessage?> Function() readInitialPushMessage,
  })  : _hasKakaoAuthorizationCallback = hasKakaoAuthorizationCallback,
        _hasAcceptedRequiredDocuments =
            hasAcceptedRequiredDocuments ?? _acceptExistingTestSession,
        _hasCompletedOnboarding = hasCompletedOnboarding,
        _markOnboardingCompleted = markOnboardingCompleted,
        _readRefreshToken = readRefreshToken,
        _refreshSession = refreshSession,
        _unregisterPushToken = unregisterPushToken,
        _clearLocalTokens = clearLocalTokens,
        _readInitialPushMessage = readInitialPushMessage;

  final bool _hasKakaoAuthorizationCallback;
  final Future<bool> Function() _hasAcceptedRequiredDocuments;
  final Future<bool> Function() _hasCompletedOnboarding;
  final Future<void> Function() _markOnboardingCompleted;
  final Future<String?> Function() _readRefreshToken;
  final Future<bool> Function() _refreshSession;
  final Future<void> Function() _unregisterPushToken;
  final Future<void> Function() _clearLocalTokens;
  final Future<PushMessage?> Function() _readInitialPushMessage;

  Future<String>? _initialRoute;
  bool _hasAcceptedRequiredDocumentsForSession = false;

  Future<String> resolveInitialRoute() {
    // 여러 위젯 프레임에서 시작 처리를 요청해도 refresh token은 한 번만 회전시킨다.
    return _initialRoute ??= _resolveInitialRoute();
  }

  Future<String> resolveInitialRouteAfterLegalConsent() {
    _hasAcceptedRequiredDocumentsForSession = true;
    _initialRoute = _resolveInitialRoute();
    return _initialRoute!;
  }

  Future<String> _resolveInitialRoute() async {
    if (!_hasAcceptedRequiredDocumentsForSession &&
        !await _readRequiredDocumentConsent()) {
      return '/legal-consent';
    }

    if (_hasKakaoAuthorizationCallback) {
      return '/login';
    }

    final hasCompletedOnboarding = await _readOnboardingStatus();
    final refreshToken = await _readStoredRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return hasCompletedOnboarding ? '/login' : '/onboarding';
    }

    // 기존 설치 사용자는 저장 플래그가 없더라도 유효한 세션이 있으면 재온보딩하지 않는다.
    await _recordCompletedOnboarding();
    final hasRestoredSession = await _restoreSession();
    if (!hasRestoredSession) {
      await _unregisterStalePushToken();
      await _clearInvalidLocalTokens();
      return '/login';
    }

    // 종료 상태 푸시는 인증 복구 뒤에만 소비해 보호 화면의 선행 API 호출을 막는다.
    final initialMessage = await _readInitialMessage();
    return PushRouteResolver.resolve(initialMessage?.data ?? const {}) ??
        '/main/map';
  }

  Future<bool> _readRequiredDocumentConsent() async {
    try {
      return await _hasAcceptedRequiredDocuments();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _readOnboardingStatus() async {
    try {
      return await _hasCompletedOnboarding();
    } catch (_) {
      return false;
    }
  }

  Future<String?> _readStoredRefreshToken() async {
    try {
      return await _readRefreshToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordCompletedOnboarding() async {
    try {
      await _markOnboardingCompleted();
    } catch (_) {
      // 로컬 설정 저장 실패가 유효한 세션 복구를 막지 않게 한다.
    }
  }

  Future<bool> _restoreSession() async {
    try {
      return await _refreshSession();
    } catch (_) {
      return false;
    }
  }

  Future<void> _unregisterStalePushToken() async {
    try {
      // 인증 토큰이 남아 있을 때 서버의 이전 사용자 푸시 등록도 함께 해제한다.
      await _unregisterPushToken();
    } catch (_) {
      // 외부 푸시 해제 실패가 만료된 세션의 로컬 정리와 로그인 진입을 막지 않게 한다.
    }
  }

  Future<void> _clearInvalidLocalTokens() async {
    try {
      await _clearLocalTokens();
    } catch (_) {
      // 로그인 화면 진입을 우선하고 다음 인증 시 저장소를 다시 덮어쓴다.
    }
  }

  Future<PushMessage?> _readInitialMessage() async {
    try {
      return await _readInitialPushMessage();
    } catch (_) {
      return null;
    }
  }
}

Future<bool> _acceptExistingTestSession() async => true;
