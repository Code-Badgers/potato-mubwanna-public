import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/config/app_environment.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
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
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required KakaoLoginService kakaoLoginService,
    required AuthRepository authRepository,
  })  : _kakaoLoginService = kakaoLoginService,
        _authRepository = authRepository,
        super(const AuthState.idle());

  final KakaoLoginService _kakaoLoginService;
  final AuthRepository _authRepository;

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
      await _authRepository.withdrawAccount();
      state = const AuthState.idle();
      return true;
    } catch (_) {
      state = const AuthState.authenticated(
        message: '회원 탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.',
      );
      return false;
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
