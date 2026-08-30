import 'dart:async';
import 'dart:ui' show SemanticsFlag;

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
import 'package:potato_mubwanna/features/reward/application/reward_history_controller.dart';
import 'package:potato_mubwanna/features/reward/domain/reward_history.dart';

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

    expect(find.text('제휴 보상은 준비 중입니다'), findsOneWidget);
    expect(find.text('감자빵 1개 교환권'), findsNothing);

    await tester.tap(find.text('로그인하고 보상 기록 저장하기'));
    await tester.pumpAndSettle();
    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('filters demo coupons by available and completed tabs', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [couponListProvider.overrideWith((ref) async => _coupons)],
    );
    await tester.pumpAndSettle();

    expect(find.text('시연용 1'), findsOneWidget);
    expect(find.text('지난 기록 2'), findsOneWidget);
    expect(find.text('공모전 시연용 쿠폰 · 실제 사용 불가'), findsOneWidget);
    expect(find.byKey(const ValueKey('coupon-1')), findsOneWidget);
    expect(find.text('감자빵 1개 교환권'), findsOneWidget);
    expect(find.text('사용한 쿠폰'), findsNothing);

    await tester.tap(find.text('지난 기록 2'));
    await tester.pumpAndSettle();

    expect(find.text('감자빵 1개 교환권'), findsNothing);
    expect(find.text('사용한 쿠폰'), findsOneWidget);
    expect(find.text('기간 만료 쿠폰'), findsOneWidget);
    expect(find.text('기간 만료'), findsOneWidget);
  });

  testWidgets('explains the actual reward earning paths', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [couponListProvider.overrideWith((ref) async => _coupons)],
    );
    await tester.pumpAndSettle();

    expect(find.text('보상은 어떻게 받을까요?'), findsOneWidget);
    expect(find.text('기본 감자 · 방문 인증 · 패스포트 · 미션'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reward-guide-banner')));
    await tester.pumpAndSettle();

    expect(find.text('보상 받는 방법'), findsOneWidget);
    expect(find.text('가입 선물'), findsOneWidget);
    expect(find.text('관광지 방문 인증'), findsOneWidget);
    expect(find.text('패스포트 스탬프'), findsOneWidget);
    expect(find.text('미션 완료'), findsOneWidget);
    expect(
      find.textContaining('쿠폰이나 스탬프를 주는 기능은 아니에요.'),
      findsOneWidget,
    );
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

  testWidgets('shows demo QR but prevents real coupon use', (tester) async {
    final repository = _DetailCouponRepository();
    await _pumpScreen(
      tester,
      overrides: [couponRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('감자빵 1개 교환권'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시연 QR 보기'));
    await tester.pumpAndSettle();

    expect(find.text('시연용 쿠폰 QR'), findsOneWidget);
    expect(find.text('공모전 시연용 쿠폰 · 실제 사용 불가'), findsWidgets);
    expect(find.text('실제 사용 불가'), findsOneWidget);
    expect(find.bySemanticsLabel('쿠폰 사용 QR 코드'), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('시연용 쿠폰 QR'), findsOneWidget);

    final disabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '실제 사용 불가'),
    );
    expect(disabledButton.onPressed, isNull);
    expect(repository.useCount, 0);
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

    expect(find.text('준비 중인 보상이에요'), findsOneWidget);
  });

  testWidgets('shows reward history with Korean type and source labels', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) async => _rewardHistory),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reward-box-history-tab')),
    );
    await tester.pumpAndSettle();

    final couponReward = find.text('강원 감자 제휴점 할인권');
    final potatoReward = find.text('수미감자 씨앗');
    expect(couponReward, findsOneWidget);
    expect(potatoReward, findsOneWidget);
    expect(
      tester.getTopLeft(couponReward).dy,
      lessThan(tester.getTopLeft(potatoReward).dy),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reward-history-2')),
        matching: find.text('쿠폰'),
      ),
      findsOneWidget,
    );
    expect(find.text('스탬프 보상'), findsOneWidget);
    expect(find.text('감자'), findsOneWidget);
    expect(find.text('미션 보상'), findsOneWidget);
    expect(find.text('2026. 07. 17. 18:30 지급'), findsOneWidget);
  });

  testWidgets('announces the selected reward box section', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) async => const []),
      ],
    );
    await tester.pumpAndSettle();

    final couponTab = find.byKey(const ValueKey('reward-box-coupon-tab'));
    final historyTab = find.byKey(const ValueKey('reward-box-history-tab'));
    expect(_isSelectedSemantics(tester, couponTab), isTrue);
    expect(_isSelectedSemantics(tester, historyTab), isFalse);

    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    expect(_isSelectedSemantics(tester, historyTab), isTrue);
    semantics.dispose();
  });

  testWidgets('keeps reward box sections usable with large text', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      textScaleFactor: 2,
      overrides: [
        couponListProvider.overrideWith((ref) async => _coupons),
        rewardHistoryProvider.overrideWith((ref) async => _rewardHistory),
      ],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('reward-box-history-tab')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('강원 감자 제휴점 할인권'), findsOneWidget);
  });

  testWidgets('shows an empty state when reward history does not exist', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) async => const []),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reward-box-history-tab')),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 받은 보상이 없어요'), findsOneWidget);
  });

  testWidgets('shows reward history loading while the request is pending', (
    tester,
  ) async {
    final completer = Completer<List<RewardHistory>?>();
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) => completer.future),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reward-box-history-tab')),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('retries after reward history loading fails', (tester) async {
    var requestCount = 0;
    await _pumpScreen(
      tester,
      overrides: [
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) {
          requestCount += 1;
          if (requestCount == 1) {
            return Future<List<RewardHistory>?>.error(Exception('network'));
          }
          return Future.value(_rewardHistory);
        }),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reward-box-history-tab')),
    );
    await tester.pumpAndSettle();

    expect(find.text('보상 내역을 불러오지 못했습니다.'), findsOneWidget);
    expect(requestCount, 1);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(requestCount, 2);
    expect(find.text('강원 감자 제휴점 할인권'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
  double textScaleFactor = 1,
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
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: _withTextScale(MediaQuery.of(context), textScaleFactor),
          child: child!,
        ),
        home: const CouponScreen(),
      ),
    ),
  );
}

bool _isSelectedSemantics(WidgetTester tester, Finder finder) {
  // Keep this test compatible with Flutter versions before flagsCollection.
  // ignore: deprecated_member_use
  return tester.getSemantics(finder).getSemanticsData().hasFlag(
        SemanticsFlag.isSelected,
      );
}

MediaQueryData _withTextScale(MediaQueryData data, double textScaleFactor) {
  // Keep this test compatible with Flutter versions before TextScaler.
  // ignore: deprecated_member_use
  return data.copyWith(textScaleFactor: textScaleFactor);
}

final _coupons = [
  _summary(1, '감자빵 1개 교환권', CouponStatus.available),
  _summary(2, '사용한 쿠폰', CouponStatus.used),
  _summary(3, '기간 만료 쿠폰', CouponStatus.expired),
];

final _rewardHistory = [
  RewardHistory(
    rewardHistoryId: 2,
    rewardType: RewardType.coupon,
    rewardName: '강원 감자 제휴점 할인권',
    sourceType: RewardSourceType.stamp,
    sourceId: 6,
    createdAt: DateTime(2026, 7, 17, 18, 30),
  ),
  RewardHistory(
    rewardHistoryId: 1,
    rewardType: RewardType.potato,
    rewardName: '수미감자 씨앗',
    sourceType: RewardSourceType.mission,
    sourceId: 1001,
    createdAt: DateTime(2026, 7, 11, 18),
  ),
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

  String? usedPayload;
  int useCount = 0;

  @override
  Future<List<CouponSummary>> fetchCoupons() async => [_coupons.first];

  @override
  Future<CouponDetail> fetchCoupon(int userCouponId) async => CouponDetail(
        userCouponId: userCouponId,
        name: '감자빵 1개 교환권',
        description: '제휴 매장에서 사용할 수 있습니다.',
        benefitAmount: 5000,
        status:
            usedPayload == null ? CouponStatus.available : CouponStatus.used,
        expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
        usagePlace: '감자마을 제휴점',
        issuedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        usedAt:
            usedPayload == null ? null : DateTime.parse('2026-07-15T00:00:00Z'),
      );

  @override
  Future<CouponQr> fetchCouponQr(int userCouponId) async => CouponQr(
        userCouponId: userCouponId,
        payload: 'signed-payload',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

  @override
  Future<CouponDetail> useCoupon(int userCouponId, String payload) async {
    useCount += 1;
    usedPayload = payload;
    return fetchCoupon(userCouponId);
  }
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
