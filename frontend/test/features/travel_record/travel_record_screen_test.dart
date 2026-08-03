import 'dart:convert';

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
import 'package:potato_mubwanna/features/travel_record/application/travel_record_controller.dart';
import 'package:potato_mubwanna/features/travel_record/domain/travel_record.dart';
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
    addTearDown(router.dispose);

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
    expect(find.byKey(const ValueKey('travel-record-list')), findsNothing);

    await tester.tap(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();

    expect(find.text('login destination'), findsOneWidget);
  });

  testWidgets('shows visit records and opens the selected spot',
      (tester) async {
    await _setMobileViewport(tester);
    final router = GoRouter(
      initialLocation: '/travel-records',
      routes: [
        GoRoute(
          path: '/travel-records',
          builder: (_, __) => const TravelRecordScreen(),
        ),
        GoRoute(
          path: '/spots/:spotId',
          builder: (_, state) => Scaffold(
            body: Text('spot ${state.pathParameters['spotId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
          travelRecordsProvider.overrideWith((ref) async => _records),
          travelRecordImageProvider.overrideWith(
            (ref, path) async => base64Decode(_onePixelPng),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('총 2곳을 방문했어요'), findsOneWidget);
    expect(find.text('감자 카페'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('정선군 · 카페'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('travel-record-uploaded-image-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('travel-record-image-fallback-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('travel-record-2')));
    await tester.pumpAndSettle();

    expect(find.text('spot 20'), findsOneWidget);
  });

  testWidgets('shows a helpful empty state without visit records',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
          travelRecordsProvider.overrideWith(
            (ref) async => const <TravelRecord>[],
          ),
        ],
        child: const MaterialApp(home: TravelRecordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 여행 기록이 없어요'), findsOneWidget);
    expect(find.textContaining('방문 인증하면'), findsOneWidget);
  });

  testWidgets('shows retry action when visit history fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
          travelRecordsProvider.overrideWith(
            (ref) => Future<List<TravelRecord>>.error(
              const _TravelRecordTestException(),
            ),
          ),
        ],
        child: const MaterialApp(home: TravelRecordScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('여행 기록을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('travel-record-retry')), findsOneWidget);
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
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _AuthenticatedAuthController(),
          ),
          travelRecordsProvider.overrideWith(
            (ref) async => const <TravelRecord>[],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('My Page destination'), findsOneWidget);
  });
}

Future<void> _setMobileViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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

class _TravelRecordTestException implements Exception {
  const _TravelRecordTestException();
}

final _records = [
  TravelRecord(
    visitId: 2,
    spotId: 20,
    spotName: '감자 카페',
    category: 'POTATO_CAFE',
    cityName: '정선군',
    address: '강원특별자치도 정선군',
    imageUrl: null,
    uploadedImageUrl: '/mission-uploads/completions/31/image',
    visitedAt: DateTime.utc(2026, 7, 27, 12),
  ),
  TravelRecord(
    visitId: 1,
    spotId: 10,
    spotName: '정선 5일장',
    category: 'POTATO_MARKET',
    cityName: '정선군',
    address: '강원특별자치도 정선군',
    imageUrl: null,
    uploadedImageUrl: null,
    visitedAt: DateTime.utc(2026, 7, 26, 9),
  ),
];

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
