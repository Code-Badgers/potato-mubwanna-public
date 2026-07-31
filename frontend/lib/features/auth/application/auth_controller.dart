import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/config/app_environment.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../push/application/push_messaging_client.dart';
import '../../push/application/push_notification_service.dart';
import '../../push/data/push_token_repository.dart';
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

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    kakaoLoginService: ref.watch(kakaoLoginServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
    pushTokenLifecycle: ref.watch(pushNotificationServiceProvider),
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required KakaoLoginService kakaoLoginService,
    required AuthRepository authRepository,
    PushTokenLifecycle pushTokenLifecycle = const NoopPushTokenLifecycle(),
  })  : _kakaoLoginService = kakaoLoginService,
        _authRepository = authRepository,
        _pushTokenLifecycle = pushTokenLifecycle,
        super(const AuthState.idle());

  final KakaoLoginService _kakaoLoginService;
  final AuthRepository _authRepository;
  final PushTokenLifecycle _pushTokenLifecycle;

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
      await _synchronizePushToken();
      state = const AuthState.authenticated();
      return true;
    } on KakaoLoginUnsupportedException catch (error) {
      state = AuthState.failure(error.message);
      return false;
    } catch (_) {
      state = const AuthState.failure('카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
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
      await _synchronizePushToken();
      state = const AuthState.authenticated();
      return true;
    } on KakaoLoginUnsupportedException catch (error) {
      state = AuthState.failure(error.message);
      return false;
    } catch (_) {
      state = const AuthState.failure('카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
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
      await _synchronizePushToken();
      state = const AuthState.authenticated();
      return true;
    } catch (_) {
      state = const AuthState.idle();
      return false;
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

  Future<void> _unregisterPushToken() async {
    try {
      await _pushTokenLifecycle.unregister();
    } catch (_) {
      // 로컬 FCM token은 lifecycle 구현에서 폐기하고 인증 종료를 계속한다.
    }
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
