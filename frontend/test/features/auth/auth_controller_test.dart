import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';

void main() {
  test('resets auth state after the remote logout request fails', () async {
    final controller = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _FailingLogoutAuthRepository(),
    );

    await controller.logout();

    expect(controller.state.status, AuthStatus.idle);
  });
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
