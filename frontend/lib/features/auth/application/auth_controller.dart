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

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
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
      final kakaoAccessToken =
          await _kakaoLoginService.loginAndReadAccessToken();
      await _authRepository.loginWithKakaoToken(kakaoAccessToken);
      state = const AuthState.authenticated();
      return true;
    } on KakaoLoginUnsupportedException catch (error) {
      state = AuthState.failure(error.message);
      return false;
    } catch (_) {
      state = const AuthState.failure(
        '카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
      );
      return false;
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
    await _authRepository.logout();
    state = const AuthState.idle();
  }
}

class AuthState {
  const AuthState._({
    required this.status,
    this.message,
  });

  const AuthState.idle() : this._(status: AuthStatus.idle);

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated() : this._(status: AuthStatus.authenticated);

  const AuthState.failure(String message)
      : this._(
          status: AuthStatus.failure,
          message: message,
        );

  final AuthStatus status;
  final String? message;
}

enum AuthStatus {
  idle,
  loading,
  authenticated,
  failure,
}
