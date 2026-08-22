import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:potato_mubwanna/core/permissions/permission_service.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';
import 'package:potato_mubwanna/features/notice/application/notice_controller.dart';
import 'package:potato_mubwanna/features/notice/domain/notice.dart';
import 'package:potato_mubwanna/features/notice/presentation/screen/notice_screen.dart';
import 'package:potato_mubwanna/features/potato/application/potato_collection_controller.dart';
import 'package:potato_mubwanna/features/potato/data/step_count_reader_stub.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/settings/presentation/screen/settings_screen.dart';
import 'package:potato_mubwanna/features/travel_record/application/travel_record_controller.dart';
import 'package:potato_mubwanna/features/travel_record/domain/travel_record.dart';
import 'package:potato_mubwanna/features/travel_record/presentation/screen/travel_record_screen.dart';

void main() {
  testWidgets('shows a login prompt instead of user data for guests',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
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

    expect(find.text('강원도 여행자'), findsOneWidget);
    expect(find.text('감자여행자'), findsNothing);
    expect(find.text('256,842'), findsNothing);
    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('로그아웃'), findsNothing);

    await tester.tap(find.text('로그인하고 기록 저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('renders traveler profile and account actions', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('마이'), findsNothing);
    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('강원도 여행자'), findsOneWidget);
    expect(find.text('GANGWON TRAVELER ID'), findsOneWidget);
    expect(find.text('강원 감자 여행자'), findsOneWidget);
    expect(find.text('GW-00001'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);

    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('감자 도감'), findsOneWidget);
    expect(find.text('스탬프 투어'), findsOneWidget);
    expect(find.text('내 미션'), findsNothing);

    expect(find.text('강원 감자 여행'), findsNothing);
    expect(find.text('기록을 확인해보세요!'), findsNothing);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('고객센터'), findsNothing);
    expect(find.text('로그아웃'), findsNothing);
    expect(find.text('회원 탈퇴'), findsNothing);
  });

  testWidgets('shows traveler profile placeholders while loading',
      (tester) async {
    final completer = Completer<UserProfile?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith((ref) => completer.future),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('GW-READY'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
  });

  testWidgets('falls back to a ready traveler profile on loading failure',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith(
            (ref) async => throw Exception('network unavailable'),
          ),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('GW-READY'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
  });

  testWidgets('clips account menu ink responses to the menu shape',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final settingsMenu = find.byKey(const ValueKey('mypage-menu-settings'));
    await tester.scrollUntilVisible(
      settingsMenu,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    for (final key in [
      'mypage-menu-coupons',
      'mypage-menu-settings',
      'mypage-menu-notices',
    ]) {
      expect(
        find.ancestor(
          of: find.byKey(ValueKey(key)),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Material && widget.clipBehavior == Clip.antiAlias,
          ),
        ),
        findsOneWidget,
      );
    }

    for (final label in ['설정', '공지사항']) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is InkWell && widget.borderRadius == null,
          ),
        ),
        findsOneWidget,
      );
    }

    for (final label in ['설정', '공지사항']) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is InkWell &&
                widget.borderRadius == null &&
                widget.onTap != null,
          ),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('opens the coupon inbox from the My Page reward action',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
        ),
        GoRoute(
          path: '/coupons',
          builder: (_, __) => const CouponScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._myPageProviderOverrides(),
          couponListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('보상함'));
    await tester.pumpAndSettle();

    expect(find.text('준비 중인 보상이에요'), findsOneWidget);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('보상함'), findsOneWidget);
  });

  testWidgets('opens travel records from the My Page quick action',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
        ),
        GoRoute(
          path: '/travel-records',
          builder: (_, __) => const TravelRecordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._myPageProviderOverrides(),
          travelRecordsProvider.overrideWith(
            (ref) async => const <TravelRecord>[],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('여행 기록'));
    await tester.pumpAndSettle();

    expect(find.text('아직 여행 기록이 없어요'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('여행 기록'), findsOneWidget);
  });

  testWidgets('opens passport stamp cards from the My Page quick action',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
        ),
        GoRoute(
          path: '/main/stamps/cities',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('passport stamp cards')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final stampTourAction =
        find.byKey(const ValueKey('mypage-quick-action-stamp-tour'));
    await tester.scrollUntilVisible(
      stampTourAction,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(stampTourAction);
    await tester.pumpAndSettle();

    expect(find.text('passport stamp cards'), findsOneWidget);
  });

  testWidgets('shows the beginner potato when no catalog potato is acquired',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          potatoCollectionProvider.overrideWith(
            (ref) async => _unacquiredPotatoCollection(),
          ),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final potatoCardsAction =
        find.byKey(const ValueKey('mypage-quick-action-potato-cards'));
    await tester.scrollUntilVisible(
      potatoCardsAction,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(potatoCardsAction);
    await tester.pumpAndSettle();

    expect(find.text('내 감자 도감'), findsOneWidget);
    expect(find.text('새싹 감자'), findsOneWidget);
    expect(find.text('#000'), findsOneWidget);
    expect(find.text('강릉 감자빵'), findsNothing);
  });

  testWidgets('opens settings from My Page account menu', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => SettingsScreen(
            permissionService: _GrantedPermissionService(),
            stepCountReader: const UnsupportedStepCountReader(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final settingsMenu = find.byKey(const ValueKey('mypage-menu-settings'));
    await tester.scrollUntilVisible(
      settingsMenu,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(settingsMenu);
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('권한 관리'), findsNothing);
  });

  testWidgets('opens notices from My Page account menu and hides support',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/main/mypage',
      routes: [
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const MyPageScreen(),
        ),
        GoRoute(
          path: '/notices',
          builder: (_, __) => const NoticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('고객센터'), findsNothing);

    final noticeMenu = find.byKey(const ValueKey('mypage-menu-notices'));
    await tester.scrollUntilVisible(
      noticeMenu,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(noticeMenu);
    await tester.pumpAndSettle();

    expect(find.text('감자 스팟 데이터는 계속 보정됩니다'), findsOneWidget);
    expect(find.text('방문 인증은 현장 위치를 기준으로 합니다'), findsOneWidget);
  });
}

List<Override> _myPageProviderOverrides({
  AuthController? authController,
  List<Override> overrides = const [],
}) {
  return [
    authControllerProvider.overrideWith(
      (ref) => authController ?? _AuthenticatedAuthController(),
    ),
    userProfileProvider.overrideWith(
      (ref) async => const UserProfile(
        userId: 1,
        nickname: '감자여행자',
        email: '',
        profileImage: '',
        createdAt: null,
      ),
    ),
    noticesProvider.overrideWith((ref) async => _notices),
    ...overrides,
  ];
}

final _notices = [
  Notice(
    id: 2,
    title: '감자 스팟 데이터는 계속 보정됩니다',
    content: '감자 스팟 정보를 최신 상태로 보정합니다.',
    publishedAt: DateTime.utc(2026, 8, 16),
  ),
  Notice(
    id: 1,
    title: '방문 인증은 현장 위치를 기준으로 합니다',
    content: '현장에서 위치를 확인해 주세요.',
    publishedAt: DateTime.utc(2026, 8, 16),
  ),
];

PotatoCollection _unacquiredPotatoCollection() {
  return const PotatoCollection(
    totalCount: 1,
    acquiredCount: 0,
    items: [
      PotatoCollectionItem(
        id: '1',
        code: 'POTATO_HAJI_GANGNEUNG',
        name: '강릉 감자빵',
        region: '강릉시',
        rarity: PotatoRarity.common,
        description: '강릉 여행길에서 만나는 감자입니다.',
        acquisitionHint: '강릉 관광지 방문 인증',
        imageUrl: null,
        acquired: false,
        acquiredAt: null,
        level: 0,
        growthDistance: 0,
        growthGoalDistance: 3000,
        representative: false,
      ),
    ],
  );
}

class _IdleAuthController extends AuthController {
  _IdleAuthController()
      : super(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: _SessionAuthRepository(),
        );
}

class _AuthenticatedAuthController extends AuthController {
  _AuthenticatedAuthController()
      : super(
          kakaoLoginService: const KakaoLoginService(),
          authRepository: _SessionAuthRepository(),
        ) {
    state = const AuthState.authenticated();
  }
}

class _SessionAuthRepository extends AuthRepository {
  _SessionAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> logout() async {}
}

class _GrantedPermissionService extends PermissionService {
  @override
  Future<PermissionStatus> locationStatus() async => PermissionStatus.granted;

  @override
  Future<PermissionStatus> notificationStatus() async =>
      PermissionStatus.granted;
}
