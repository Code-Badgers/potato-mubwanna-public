import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/push/application/push_notification_service.dart';

void main() {
  test('keeps auth idle while web login redirects to Kakao', () async {
    final controller = AuthController(
      kakaoLoginService: _RedirectKakaoLoginService(),
      authRepository: _RecordingAuthRepository(),
    );

    final loggedIn = await controller.loginWithKakao();

    expect(loggedIn, isFalse);
    expect(controller.state.status, AuthStatus.idle);
  });

  test('completes web login from a verified authorization callback', () async {
    final service = _CallbackKakaoLoginService();
    final repository = _RecordingAuthRepository();
    final pushLifecycle = _RecordingPushTokenLifecycle();
    final controller = AuthController(
      kakaoLoginService: service,
      authRepository: repository,
      pushTokenLifecycle: pushLifecycle,
    );

    final loggedIn = await controller.completePendingKakaoLogin();

    expect(loggedIn, isTrue);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(repository.authorizationCode, 'authorization-code');
    expect(repository.redirectUri, 'http://localhost:54631/');
    expect(service.cleared, isTrue);
    expect(pushLifecycle.synchronizeCalls, 1);
  });

  test('resets auth state after the remote logout request fails', () async {
    final pushLifecycle = _RecordingPushTokenLifecycle();
    final controller = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _FailingLogoutAuthRepository(),
      pushTokenLifecycle: pushLifecycle,
    );

    await controller.logout();

    expect(controller.state.status, AuthStatus.idle);
    expect(pushLifecycle.unregisterCalls, 1);
  });

  test('returns to idle after account withdrawal succeeds', () async {
    final repository = _RecordingAuthRepository();
    final controller = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: repository,
    );
    controller.state = const AuthState.authenticated();

    final withdrawn = await controller.withdrawAccount();

    expect(withdrawn, isTrue);
    expect(repository.withdrawalCalls, 1);
    expect(controller.state.status, AuthStatus.idle);
  });

  test('keeps authenticated state when account withdrawal fails', () async {
    final controller = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _FailingWithdrawalAuthRepository(),
    );
    controller.state = const AuthState.authenticated();

    final withdrawn = await controller.withdrawAccount();

    expect(withdrawn, isFalse);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.message, contains('회원 탈퇴에 실패'));
  });
}

class _RedirectKakaoLoginService extends KakaoLoginService {
  @override
  Future<KakaoLoginResult> login() async {
    return const KakaoAuthorizationRedirectResult();
  }
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

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  String? authorizationCode;
  String? redirectUri;
  int withdrawalCalls = 0;

  @override
  Future<void> loginWithKakaoAuthorizationCode({
    required String authorizationCode,
    required String redirectUri,
  }) async {
    this.authorizationCode = authorizationCode;
    this.redirectUri = redirectUri;
  }

  @override
  Future<void> withdrawAccount() async {
    withdrawalCalls++;
  }
}

class _FailingLogoutAuthRepository extends AuthRepository {
  _FailingLogoutAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> logout() {
    throw StateError('remote logout failed');
  }
}

class _FailingWithdrawalAuthRepository extends AuthRepository {
  _FailingWithdrawalAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> withdrawAccount() {
    throw StateError('account withdrawal failed');
  }
}

class _RecordingPushTokenLifecycle implements PushTokenLifecycle {
  int synchronizeCalls = 0;
  int unregisterCalls = 0;

  @override
  Future<void> synchronize() async {
    synchronizeCalls++;
  }

  @override
  Future<void> unregister() async {
    unregisterCalls++;
  }
}
