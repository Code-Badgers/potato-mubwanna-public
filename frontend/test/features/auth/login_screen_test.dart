import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/auth/presentation/screen/login_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('renders kakao login entry points', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.text('Apple 로그인 준비 중'), findsNothing);
    expect(find.text('나중에 로그인하기'), findsOneWidget);
  });

  testWidgets('shows unsupported message when kakao login cannot start',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthController(
                kakaoLoginService: _UnsupportedKakaoLoginService(),
                authRepository: _NoopAuthRepository(),
              ),
            ),
          ],
          child: const LoginScreen(),
        ),
      ),
    );

    await tester.tap(find.text('카카오 로그인'));
    await tester.pump();
    await tester.pump();

    expect(find.text('테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.'), findsOneWidget);
  });
}

class _UnsupportedKakaoLoginService extends KakaoLoginService {
  @override
  Future<String> loginAndReadAccessToken() {
    throw const KakaoLoginUnsupportedException(
      '테스트 환경에서는 카카오 로그인을 시작할 수 없습니다.',
    );
  }
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> loginWithKakaoToken(String kakaoAccessToken) async {}
}
