import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/config/app_environment.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../push/application/push_messaging_client.dart';
import '../../push/application/push_notification_service.dart';
import '../../push/data/push_token_repository.dart';
import '../../legal/data/legal_consent_store.dart';
import '../../legal/data/legal_consent_sync_service.dart';
import '../data/auth_repository.dart';
import '../data/kakao_login_service.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(FlutterSecureStorage()),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    baseUrl: AppEnvironment.apiBaseUrl,
  ),
);

final kakaoLoginServiceProvider = Provider<KakaoLoginService>(
  (ref) => const KakaoLoginService(),
);

final pushMessagingClientProvider = Provider<PushMessagingClient>(
  (ref) => const DisabledPushMessagingClient(),
);

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => PushTokenRepository(dio: ref.watch(dioClientProvider).dio),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) {
    final service = PushNotificationService(
      messagingClient: ref.watch(pushMessagingClientProvider),
      pushTokenRepository: ref.watch(pushTokenRepositoryProvider),
      pushTokenStore: ref.watch(tokenStorageProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    dio: ref.watch(dioClientProvider).dio,
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final legalConsentSyncServiceProvider = Provider<LegalConsentSyncService>(
  (ref) => LegalConsentSyncService(
    dio: ref.watch(dioClientProvider).dio,
    store: ref.watch(legalConsentStoreProvider),
  ),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    kakaoLoginService: ref.watch(kakaoLoginServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
    pushTokenLifecycle: ref.watch(pushNotificationServiceProvider),
    legalConsentLifecycle: ref.watch(legalConsentSyncServiceProvider),
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required KakaoLoginService kakaoLoginService,
    required AuthRepository authRepository,
    PushTokenLifecycle pushTokenLifecycle = const NoopPushTokenLifecycle(),
    LegalConsentLifecycle legalConsentLifecycle =
        const NoopLegalConsentLifecycle(),
  })  : _kakaoLoginService = kakaoLoginService,
        _authRepository = authRepository,
        _pushTokenLifecycle = pushTokenLifecycle,
        _legalConsentLifecycle = legalConsentLifecycle,
        super(const AuthState.idle());

  final KakaoLoginService _kakaoLoginService;
  final AuthRepository _authRepository;
  final PushTokenLifecycle _pushTokenLifecycle;
  final LegalConsentLifecycle _legalConsentLifecycle;

  Future<bool> loginWithKakao() async {
    state = const AuthState.loading();
    try {
      final result = await _kakaoLoginService.login();
      if (result is KakaoAuthorizationRedirectResult) {
        state = const AuthState.idle();
        return false;
      }
      final kakaoAccessToken =
          (result as KakaoAccessTokenLoginResult).accessToken;
      await _authRepository.loginWithKakaoToken(kakaoAccessToken);
      _completeAuthentication();
      return true;
    } on KakaoLoginUnsupportedException catch (error) {
      state = AuthState.failure(error.message);
      return false;
    } on ApiException catch (error) {
      _recordBackendLoginFailure(error);
      state = AuthState.failure(_backendLoginFailureMessage(error));
      return false;
    } catch (error) {
      _recordKakaoSdkFailure(error);
      state = const AuthState.failure(
        '카카오 인증 단계에서 실패했습니다. 카카오톡 상태와 네트워크를 확인해주세요.',
      );
      return false;
    }
  }

  Future<bool> completePendingKakaoLogin() async {
    KakaoAuthorizationCallback? callback;
    try {
      callback = _kakaoLoginService.readAuthorizationCallback();
      if (callback == null) {
        return false;
      }

      state = const AuthState.loading();
      await _authRepository.loginWithKakaoAuthorizationCode(
        authorizationCode: callback.authorizationCode,
        redirectUri: callback.redirectUri,
      );
      _completeAuthentication();
      return true;
    } on KakaoLoginUnsupportedException catch (error) {
      state = AuthState.failure(error.message);
      return false;
    } on ApiException catch (error) {
      _recordBackendLoginFailure(error);
      state = AuthState.failure(_backendLoginFailureMessage(error));
      return false;
    } catch (error) {
      _recordKakaoSdkFailure(error);
      state = const AuthState.failure(
        '카카오 인증 단계에서 실패했습니다. 카카오톡 상태와 네트워크를 확인해주세요.',
      );
      return false;
    } finally {
      if (callback != null || AppEnvironment.hasKakaoAuthorizationCallback) {
        _kakaoLoginService.clearAuthorizationCallback();
      }
    }
  }

  Future<bool> refreshSession() async {
    state = const AuthState.loading();
    try {
      await _authRepository.refreshSession();
      _completeAuthentication();
      return true;
    } on ApiException catch (error) {
      // 서버가 토큰을 명확히 거절한 경우에만 저장된 세션을 폐기하도록 알린다.
      if (error.statusCode == 401) {
        state = const AuthState.idle();
        return false;
      }
      state = const AuthState.failure('로그인 상태를 확인하지 못했어요. 다시 시도해주세요.');
      rethrow;
    } catch (_) {
      state = const AuthState.failure('로그인 상태를 확인하지 못했어요. 다시 시도해주세요.');
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _unregisterPushToken();
      await _authRepository.logout();
    } catch (_) {
      // AuthRepository clears local tokens even when remote revocation fails.
    } finally {
      state = const AuthState.idle();
    }
  }

  Future<bool> withdrawAccount() async {
    state = const AuthState.loading();
    try {
      await _unregisterPushToken();
      await _authRepository.withdrawAccount();
      state = const AuthState.idle();
      return true;
    } catch (_) {
      await _synchronizePushToken();
      state = const AuthState.authenticated(
        message: '회원 탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.',
      );
      return false;
    }
  }

  Future<void> _synchronizePushToken() async {
    try {
      await _pushTokenLifecycle.synchronize();
    } catch (_) {
      // 푸시 비활성화나 일시 장애가 로그인 성공을 막지 않게 한다.
    }
  }

  Future<void> _synchronizeLegalConsent() async {
    try {
      await _legalConsentLifecycle.synchronize();
    } catch (_) {
      // 네트워크 장애가 로그인을 막지 않게 하고 다음 세션에서 재시도한다.
    }
  }

  void _completeAuthentication() {
    state = const AuthState.authenticated();
    // 푸시 및 약관 보강 실패는 인증 결과와 무관하므로 첫 화면을 연 뒤 병렬 처리한다.
    unawaited(
      Future.wait([
        _synchronizePushToken(),
        _synchronizeLegalConsent(),
      ]),
    );
  }

  Future<void> _unregisterPushToken() async {
    try {
      await _pushTokenLifecycle.unregister();
    } catch (_) {
      // 로컬 FCM token은 lifecycle 구현에서 폐기하고 인증 종료를 계속한다.
    }
  }

  String _backendLoginFailureMessage(ApiException error) {
    final status = error.statusCode;
    final statusLabel = status == null ? '' : ' ($status)';
    if (status == 401) {
      return '카카오 인증은 완료됐지만 서버 로그인에 실패했습니다$statusLabel. 다시 시도해주세요.';
    }
    return '카카오 인증은 완료됐지만 서버 로그인에 실패했습니다$statusLabel. ${error.message}';
  }

  void _recordBackendLoginFailure(ApiException error) {
    developer.log(
      'Kakao backend token exchange failed '
      '(status=${error.statusCode ?? 'none'}, code=${error.code ?? 'none'}).',
      name: 'auth',
    );
  }

  void _recordKakaoSdkFailure(Object error) {
    developer.log(
      'Kakao SDK login failed (type=${error.runtimeType}).',
      name: 'auth',
    );
  }
}

class AuthState {
  const AuthState._({required this.status, this.message});

  const AuthState.idle() : this._(status: AuthStatus.idle);

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated({String? message})
      : this._(status: AuthStatus.authenticated, message: message);

  const AuthState.failure(String message)
      : this._(status: AuthStatus.failure, message: message);

  final AuthStatus status;
  final String? message;
}

enum AuthStatus { idle, loading, authenticated, failure }
