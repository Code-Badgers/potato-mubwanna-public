import 'dart:async';

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
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/coupon/data/coupon_repository.dart';
import 'package:potato_mubwanna/features/coupon/domain/coupon.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';

void main() {
  testWidgets('shows a login prompt instead of coupons for guests', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/coupons',
      routes: [
        GoRoute(path: '/coupons', builder: (_, __) => const CouponScreen()),
        GoRoute(
          path: '/login',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('login destination'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _IdleAuthController()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('로그인이 필요한 서비스예요'), findsOneWidget);
    expect(find.text('감자빵 1개 교환권'), findsNothing);

    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();
    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('filters real coupons by available and completed tabs', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [couponListProvider.overrideWith((ref) async => _coupons)],
    );
    await tester.pumpAndSettle();

    expect(find.text('사용 가능 1'), findsOneWidget);
    expect(find.text('사용 완료 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('coupon-1')), findsOneWidget);
    expect(find.text('감자빵 1개 교환권'), findsOneWidget);
    expect(find.text('사용한 쿠폰'), findsNothing);

    await tester.tap(find.text('사용 완료 2'));
    await tester.pumpAndSettle();

    expect(find.text('감자빵 1개 교환권'), findsNothing);
    expect(find.text('사용한 쿠폰'), findsOneWidget);
    expect(find.text('기간 만료 쿠폰'), findsOneWidget);
    expect(find.text('기간 만료'), findsOneWidget);
  });

  testWidgets('opens coupon detail from a coupon card', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [
        couponRepositoryProvider.overrideWithValue(_DetailCouponRepository()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('감자빵 1개 교환권'));
    await tester.pumpAndSettle();

    expect(find.text('쿠폰 상세'), findsOneWidget);
    expect(find.text('감자마을 제휴점'), findsOneWidget);
    expect(find.text('2026. 07. 01. 발급'), findsOneWidget);
    expect(find.text('QR 코드는 다음 업데이트에서 제공됩니다.'), findsNothing);
  });

  testWidgets('shows a loading state while coupons are requested', (
    tester,
  ) async {
    final completer = Completer<List<CouponSummary>?>();
    await _pumpScreen(
      tester,
      overrides: [couponListProvider.overrideWith((ref) => completer.future)],
    );

    expect(find.text('보상함'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error state with a retry action', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith(
          (ref) => Future<List<CouponSummary>?>.error(Exception('network')),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('쿠폰을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('shows an empty state for a tab without coupons', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [couponListProvider.overrideWith((ref) async => const [])],
    );
    await tester.pumpAndSettle();

    expect(find.text('사용 가능한 쿠폰이 없어요.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedAuthController(),
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: CouponScreen()),
    ),
  );
}

final _coupons = [
  _summary(1, '감자빵 1개 교환권', CouponStatus.available),
  _summary(2, '사용한 쿠폰', CouponStatus.used),
  _summary(3, '기간 만료 쿠폰', CouponStatus.expired),
];

CouponSummary _summary(int id, String name, CouponStatus status) =>
    CouponSummary(
      userCouponId: id,
      name: name,
      description: '제휴 매장에서 사용할 수 있습니다.',
      benefitAmount: 5000,
      status: status,
      expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
    );

class _DetailCouponRepository extends CouponRepository {
  _DetailCouponRepository() : super(dio: Dio());

  @override
  Future<List<CouponSummary>> fetchCoupons() async => [_coupons.first];

  @override
  Future<CouponDetail> fetchCoupon(int userCouponId) async => CouponDetail(
        userCouponId: userCouponId,
        name: '감자빵 1개 교환권',
        description: '제휴 매장에서 사용할 수 있습니다.',
        benefitAmount: 5000,
        status: CouponStatus.available,
        expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
        usagePlace: '감자마을 제휴점',
        issuedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        usedAt: null,
      );
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
