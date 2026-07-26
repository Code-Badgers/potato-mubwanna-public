import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';

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
    final controller = AuthController(
      kakaoLoginService: service,
      authRepository: repository,
    );

    final loggedIn = await controller.completePendingKakaoLogin();

    expect(loggedIn, isTrue);
    expect(controller.state.status, AuthStatus.authenticated);
    expect(repository.authorizationCode, 'authorization-code');
    expect(repository.redirectUri, 'http://localhost:54631/');
    expect(service.cleared, isTrue);
  });

  test('resets auth state after the remote logout request fails', () async {
    final controller = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _FailingLogoutAuthRepository(),
    );

    await controller.logout();

    expect(controller.state.status, AuthStatus.idle);
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

  @override
  Future<void> loginWithKakaoAuthorizationCode({
    required String authorizationCode,
    required String redirectUri,
  }) async {
    this.authorizationCode = authorizationCode;
    this.redirectUri = redirectUri;
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
