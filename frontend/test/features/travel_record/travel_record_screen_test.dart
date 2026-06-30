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
import 'package:potato_mubwanna/features/travel_record/presentation/screen/travel_record_screen.dart';

void main() {
  testWidgets('shows a login prompt instead of travel records for guests',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/travel-records',
      routes: [
        GoRoute(
          path: '/travel-records',
          builder: (_, __) => const TravelRecordScreen(),
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
    expect(find.text('정선 5일장'), findsNothing);
    expect(find.text('스탬프 획득'), findsNothing);

    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('shows a preparation state without placeholder records',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
        ],
        child: const MaterialApp(home: TravelRecordScreen()),
      ),
    );

    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('여행 기록 연동을 준비하고 있어요.'), findsOneWidget);
    expect(find.text('정선 5일장'), findsNothing);
    expect(find.text('강릉 커피거리'), findsNothing);
    expect(find.text('스탬프 획득'), findsNothing);
  });

  testWidgets('returns to My Page when opened without a back stack',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/travel-records',
      routes: [
        GoRoute(
          path: '/travel-records',
          builder: (_, __) => const TravelRecordScreen(),
        ),
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('My Page destination')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('My Page destination'), findsOneWidget);
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
