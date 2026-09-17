import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/app.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/push/application/push_messaging_client.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows foreground push content only while authenticated', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final messagingClient = _TestPushMessagingClient();
    final authController = _TestAuthController();
    addTearDown(messagingClient.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushMessagingClientProvider.overrideWithValue(messagingClient),
          authControllerProvider.overrideWith((ref) => authController),
        ],
        child: const PotatoMubwannaApp(),
      ),
    );
    await tester.pump();

    messagingClient.emitForeground(
      const PushMessage(
        title: '이전 사용자 알림',
        body: '로그아웃 상태에서는 보이면 안 됩니다.',
        data: {'destination': 'COUPONS'},
      ),
    );
    await tester.pump();

    expect(find.textContaining('이전 사용자 알림'), findsNothing);

    authController.authenticate();
    await tester.pump();
    messagingClient.emitForeground(
      const PushMessage(
        title: '현재 사용자 알림',
        body: '로그인 상태에서는 표시됩니다.',
        data: {'destination': 'COUPONS'},
      ),
    );
    await tester.pump();

    expect(find.textContaining('현재 사용자 알림'), findsOneWidget);
    expect(find.text('보기'), findsOneWidget);

    authController.signOut();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('현재 사용자 알림'), findsNothing);
    expect(find.text('보기'), findsNothing);
  });
}

class _TestPushMessagingClient extends DisabledPushMessagingClient {
  final _foregroundMessages = StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get foregroundMessages => _foregroundMessages.stream;

  void emitForeground(PushMessage message) {
    _foregroundMessages.add(message);
  }

  Future<void> dispose() => _foregroundMessages.close();
}

class _TestAuthController extends AuthController {
  _TestAuthController()
      : super(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: _TestAuthRepository(),
        );

  void authenticate() {
    state = const AuthState.authenticated();
  }

  void signOut() {
    state = const AuthState.idle();
  }
}

class _TestAuthRepository extends AuthRepository {
  _TestAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );
}
