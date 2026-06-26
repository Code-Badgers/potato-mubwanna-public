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
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';
import 'package:potato_mubwanna/features/settings/presentation/screen/settings_screen.dart';
import 'package:potato_mubwanna/features/travel_record/presentation/screen/travel_record_screen.dart';

void main() {
  testWidgets('renders profile summary, quick actions, and account menu',
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

    expect(find.text('마이'), findsOneWidget);
    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('Lv.2'), findsOneWidget);
    expect(find.text('6,420 / 10,000'), findsOneWidget);

    expect(find.text('누적 걸음 수'), findsOneWidget);
    expect(find.text('256,842'), findsOneWidget);
    expect(find.text('누적 스탬프 수'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('보유 감자 수'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

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

  testWidgets('renders the fetched nickname in the profile summary',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides([
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
        overrides: _myPageProviderOverrides([
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

  testWidgets('keeps the fallback profile when loading fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _myPageProviderOverrides([
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

    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.byIcon(Icons.face_3_rounded), findsOneWidget);
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
        overrides: _myPageProviderOverrides([
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              kakaoLoginService: const KakaoLoginService(),
              authRepository: authRepository,
            ),
          ),
        ]),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

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
        overrides: _myPageProviderOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('보상함'));
    await tester.pumpAndSettle();

    expect(find.text('사용 가능 2'), findsOneWidget);
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
        overrides: _myPageProviderOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('여행 기록'));
    await tester.pumpAndSettle();

    expect(find.text('총 3곳 방문'), findsOneWidget);
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

List<Override> _myPageProviderOverrides([List<Override> overrides = const []]) {
  return [
    userProfileProvider.overrideWith(
      (ref) async => const UserProfile(
        userId: 1,
        nickname: '감자여행자',
        email: 'user@example.com',
        profileImage: '',
        createdAt: null,
      ),
    ),
    ...overrides,
  ];
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
  Future<void> logout() {
    logoutCalls++;
    return _logoutCompleter.future;
  }

  void completeLogout() {
    _logoutCompleter.complete();
  }
}

class _GrantedPermissionService extends PermissionService {
  @override
  Future<PermissionStatus> locationStatus() async => PermissionStatus.granted;

  @override
  Future<PermissionStatus> notificationStatus() async =>
      PermissionStatus.granted;
}
