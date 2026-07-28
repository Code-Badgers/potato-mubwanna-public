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
import 'package:potato_mubwanna/features/mypage/application/user_activity_summary_controller.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_activity_summary.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';
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

    expect(find.text('로그인이 필요한 서비스예요'), findsOneWidget);
    expect(find.text('감자여행자'), findsNothing);
    expect(find.text('256,842'), findsNothing);
    expect(find.text('보상함'), findsNothing);
    expect(find.text('로그아웃'), findsNothing);

    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('renders real profile and activity summary data', (tester) async {
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

    expect(find.text('마이'), findsOneWidget);
    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('Lv.2'), findsNothing);
    expect(find.text('6,420 / 10,000'), findsNothing);

    expect(find.text('누적 걸음 수'), findsOneWidget);
    expect(find.text('256,842'), findsOneWidget);
    expect(find.text('누적 스탬프 수'), findsOneWidget);
    expect(find.text('보유 감자 수'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('-'), findsNothing);

    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('내 미션'), findsOneWidget);
    expect(find.text('감자 도감'), findsOneWidget);

    expect(find.text('강원 감자 여행'), findsOneWidget);
    expect(find.text('기록을 확인해보세요!'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('고객센터'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('shows activity summary loading placeholders', (tester) async {
    final completer = Completer<UserActivitySummary?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userActivitySummaryProvider.overrideWith((ref) => completer.future),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('…'), findsNWidgets(3));
  });

  testWidgets('shows an activity summary retry action on failure',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userActivitySummaryProvider.overrideWith(
            (ref) async => throw Exception('network unavailable'),
          ),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('-'), findsNWidgets(3));
    expect(find.text('활동 요약 다시 시도'), findsOneWidget);
  });

  testWidgets('renders the fetched nickname in the profile summary',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              userId: 1,
              nickname: '실제 사용자',
              email: 'user@example.com',
              profileImage: 'https://example.com/profile.png',
              createdAt: null,
            ),
          ),
        ]),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('실제 사용자'), findsOneWidget);
    expect(find.text('감자여행자'), findsNothing);
  });

  testWidgets('uses the default avatar when profile image is absent',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              userId: 1,
              nickname: '이미지 없는 사용자',
              email: 'user@example.com',
              profileImage: '',
              createdAt: null,
            ),
          ),
        ]),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이미지 없는 사용자'), findsOneWidget);
    expect(find.byIcon(Icons.face_3_rounded), findsOneWidget);
  });

  testWidgets('shows a profile error instead of fallback user data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith(
            (ref) async => throw Exception('network unavailable'),
          ),
        ]),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('내 정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('감자여행자'), findsNothing);
  });

  testWidgets(
      'shows a profile-specific state for an authenticated null profile',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(overrides: [
          userProfileProvider.overrideWith((ref) async => null),
        ]),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('프로필 정보를 찾을 수 없습니다.'), findsOneWidget);
    expect(find.text('마이페이지를 확인하려면 로그인해주세요.'), findsNothing);
    expect(find.text('로그인하기'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('clips account menu ink responses to the menu shape',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Material &&
            widget.color == const Color(0xFFFFF8EA) &&
            widget.clipBehavior == Clip.antiAlias,
      ),
      findsOneWidget,
    );

    for (final label in ['설정', '공지사항', '고객센터']) {
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

    for (final label in ['설정', '공지사항', '고객센터']) {
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

  testWidgets('logs out once and replaces My Page with the login screen',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = _ControlledLogoutAuthRepository();
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: authRepository,
    );
    await authController.refreshSession();
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
        overrides: _myPageProviderOverrides(authController: authController),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final logout = find.text('로그아웃');
    await tester.scrollUntilVisible(logout, 200);
    await tester.tap(logout);
    await tester.pump();

    expect(authRepository.logoutCalls, 1);
    expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    authRepository.completeLogout();
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('confirms account withdrawal before deleting and opens login',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = _ControlledWithdrawalAuthRepository();
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: authRepository,
    );
    await authController.refreshSession();
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
        overrides: _myPageProviderOverrides(authController: authController),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final withdrawal = find.text('회원 탈퇴');
    await tester.scrollUntilVisible(withdrawal, 200);
    await tester.tap(withdrawal);
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴하시겠어요?'), findsOneWidget);
    expect(find.textContaining('복구할 수 없습니다'), findsOneWidget);
    expect(authRepository.withdrawalCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, '회원 탈퇴'));
    await tester.pump();

    expect(authRepository.withdrawalCalls, 1);
    expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    authRepository.completeWithdrawal();
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('keeps My Page and explains account withdrawal failure',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _FailingWithdrawalAuthRepository(),
    );
    await authController.refreshSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(authController: authController),
        child: const MaterialApp(home: MyPageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final withdrawal = find.text('회원 탈퇴');
    await tester.scrollUntilVisible(withdrawal, 200);
    await tester.tap(withdrawal);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '회원 탈퇴'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('회원 탈퇴에 실패했습니다'), findsOneWidget);
    expect(authController.state.status, AuthStatus.authenticated);
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

    expect(find.text('사용 가능한 쿠폰이 없어요.'), findsOneWidget);
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

  testWidgets('opens settings from My Page header and account menu',
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
          path: '/settings',
          builder: (_, __) => SettingsScreen(
            permissionService: _GrantedPermissionService(),
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

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('권한 관리'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    final settingsMenu = find.text('설정');
    await tester.scrollUntilVisible(settingsMenu, 200);
    await tester.tap(settingsMenu);
    await tester.pumpAndSettle();

    expect(find.text('권한 관리'), findsOneWidget);
  });

  testWidgets('disables quick actions without a destination', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides(),
        child: const MaterialApp(
          home: MyPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final icon in [
      Icons.assignment_turned_in_rounded,
      Icons.inventory_2_rounded,
    ]) {
      expect(
        find.ancestor(
          of: find.byIcon(icon),
          matching: find.byWidgetPredicate(
            (widget) => widget is InkWell && widget.onTap == null,
          ),
        ),
        findsOneWidget,
      );
    }
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
        email: 'user@example.com',
        profileImage: '',
        createdAt: null,
      ),
    ),
    userActivitySummaryProvider.overrideWith(
      (ref) async => const UserActivitySummary(
        totalSteps: 256842,
        stampCount: 12,
        ownedPotatoCount: 7,
      ),
    ),
    ...overrides,
  ];
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

class _ControlledLogoutAuthRepository extends AuthRepository {
  _ControlledLogoutAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  final _logoutCompleter = Completer<void>();
  int logoutCalls = 0;

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> logout() {
    logoutCalls++;
    return _logoutCompleter.future;
  }

  void completeLogout() {
    _logoutCompleter.complete();
  }
}

class _ControlledWithdrawalAuthRepository extends AuthRepository {
  _ControlledWithdrawalAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  final _withdrawalCompleter = Completer<void>();
  int withdrawalCalls = 0;

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> withdrawAccount() {
    withdrawalCalls++;
    return _withdrawalCompleter.future;
  }

  void completeWithdrawal() {
    _withdrawalCompleter.complete();
  }
}

class _FailingWithdrawalAuthRepository extends AuthRepository {
  _FailingWithdrawalAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> withdrawAccount() {
    throw StateError('account withdrawal failed');
  }
}

class _GrantedPermissionService extends PermissionService {
  @override
  Future<PermissionStatus> locationStatus() async => PermissionStatus.granted;

  @override
  Future<PermissionStatus> notificationStatus() async =>
      PermissionStatus.granted;
}
