import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';

void main() {
  testWidgets('shows a login prompt instead of coupons for guests',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/coupons',
      routes: [
        GoRoute(
          path: '/coupons',
          builder: (_, __) => const CouponScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('login destination')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _IdleAuthController(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('로그인이 필요한 서비스예요'), findsOneWidget);
    expect(find.text('강원 감자 여행 상품권'), findsNothing);
    expect(find.text('QR 보기'), findsNothing);

    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('shows a preparation state without placeholder coupons',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
        ],
        child: const MaterialApp(home: CouponScreen()),
      ),
    );

    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('보상 데이터 연동을 준비하고 있어요.'), findsOneWidget);
    expect(find.text('강원 감자 여행 상품권'), findsNothing);
    expect(find.text('5,000원'), findsNothing);
    expect(find.text('QR 보기'), findsNothing);
  });
}

class _IdleAuthController extends AuthController {
  _IdleAuthController()
      : super(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: _AuthRepository(),
        );
}

class _AuthenticatedAuthController extends AuthController {
  _AuthenticatedAuthController()
      : super(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: _AuthRepository(),
        ) {
    state = const AuthState.authenticated();
  }
}

class _AuthRepository extends AuthRepository {
  _AuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );
}
