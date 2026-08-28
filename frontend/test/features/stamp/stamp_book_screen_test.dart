import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/stamp/application/stamp_book_controller.dart';
import 'package:potato_mubwanna/features/stamp/data/stamp_repository.dart';
import 'package:potato_mubwanna/features/stamp/domain/stamp_book.dart';
import 'package:potato_mubwanna/features/stamp/presentation/screen/stamp_book_screen.dart';

void main() {
  testWidgets('renders a map-first stamp tour and selected city card', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      rallybookSpotsOverride: stampRallybookSpotsProvider.overrideWith(
        (ref) async => _rallybookSpots,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsNothing);
    expect(find.text('스탬프 투어'), findsNothing);
    expect(find.text('강원도 지도 위에 도장을 모아보세요'), findsNothing);
    expect(find.text('패스포트  2/3'), findsOneWidget);
    expect(find.text('12개 달성까지 4개 남았어요'), findsNothing);
    expect(find.text('다음 스탬프 추천'), findsNothing);
    expect(find.text('지도의 시군을 눌러 스탬프 상태를 확인해보세요.'), findsNothing);
    expect(
      find.byKey(const ValueKey('rallybook-spot-marker-101')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('rallybook-spot-marker-102')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('rallybook-spot-marker-103')),
      findsOneWidget,
    );
    expect(find.text('여행할 명소를 골라보세요'), findsOneWidget);
    expect(find.text('강원 여행 패스포트'), findsOneWidget);
    expect(find.text('지도에서 깃발 선택'), findsNothing);
    expect(find.text('방문 인증하기'), findsNothing);

    await _tapMapMarker(tester, 101);
    await tester.pumpAndSettle();

    expect(find.text('여행할 명소를 골라보세요'), findsNothing);
    expect(find.text('정선 5일장'), findsWidgets);
    expect(find.text('정선 · 도장 획득'), findsNothing);
    expect(find.text('대표 스팟 보기'), findsNothing);
    expect(find.text('오디오 준비중'), findsNothing);
    expect(find.text('스탬프 준비중'), findsNothing);
    expect(find.text('방문 인증하기'), findsOneWidget);
    expect(find.text('투어 진행률'), findsNothing);
  });

  testWidgets('updates the card between multiple spots in the same city', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      rallybookSpotsOverride: stampRallybookSpotsProvider.overrideWith(
        (ref) async => _rallybookSpots,
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapMarker(tester, 102);
    await tester.pumpAndSettle();
    expect(find.text('남이섬'), findsWidgets);
    expect(find.text('춘천 · 도장 획득'), findsNothing);

    await _tapMapMarker(tester, 103);
    await tester.pumpAndSettle();
    expect(find.text('소양강 스카이워크'), findsWidgets);
    expect(find.text('춘천 · 방문 인증 대기'), findsNothing);
  });

  testWidgets('opens the selected stamp spot detail', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const StampBookScreen()),
        GoRoute(
          path: '/spots/:spotId',
          builder: (_, state) => Text('상세 ${state.pathParameters['spotId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampBookProvider.overrideWith((ref) async => _stampBook()),
          stampRallybookSpotsProvider.overrideWith(
            (ref) async => _rallybookSpots,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapMarker(tester, 101);
    await tester.pumpAndSettle();

    await tester.tap(find.text('방문 인증하기'));
    await tester.pumpAndSettle();

    expect(find.text('상세 101'), findsOneWidget);
  });

  testWidgets('selects nearby markers by their nearest map coordinate', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      rallybookSpotsOverride: stampRallybookSpotsProvider.overrideWith(
        (ref) async => _nearbyRallybookSpots,
      ),
    );
    await tester.pumpAndSettle();

    final firstMarker = find.byKey(
      const ValueKey('rallybook-spot-marker-201'),
    );
    final secondMarker = find.byKey(
      const ValueKey('rallybook-spot-marker-202'),
    );
    final firstCenter = tester.getCenter(firstMarker);
    final secondCenter = tester.getCenter(secondMarker);

    expect((firstCenter - secondCenter).distance, lessThan(40));

    await tester.tapAt(firstCenter);
    await tester.pumpAndSettle();
    expect(find.text('가까운 장소 A'), findsWidgets);

    await tester.tapAt(secondCenter);
    await tester.pumpAndSettle();
    expect(find.text('가까운 장소 B'), findsWidgets);
  });

  testWidgets('opens passport stamp cards from the map progress badge', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const StampBookScreen()),
        GoRoute(
          path: '/main/stamps/cities',
          builder: (_, __) => const Text('시군별 스탬프 카드'),
        ),
      ],
    );
    addTearDown(router.dispose);

    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampBookProvider.overrideWith((ref) async => _stampBook()),
          stampRallybookSpotsProvider.overrideWith(
            (ref) async => _rallybookSpots,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('강원 여행 패스포트 보기'));
    await tester.pumpAndSettle();

    expect(find.text('시군별 스탬프 카드'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('여행할 명소를 골라보세요'), findsOneWidget);
    expect(find.text('패스포트  2/3'), findsOneWidget);
  });

  testWidgets('renders passport stamp card grid', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampBookProvider.overrideWith((ref) async => _stampBook()),
          stampRallybookSpotsProvider.overrideWith(
            (ref) async => _rallybookSpots,
          ),
        ],
        child: const MaterialApp(home: PassportStampGridScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('강원 여행 패스포트'), findsOneWidget);
    expect(find.text('명소에서 인증하면 스탬프가 채워져요'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('춘천'), findsWidgets);
    expect(find.text('정선'), findsOneWidget);
    expect(find.text('남이섬'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
  });

  testWidgets('keeps stamp tour visible when rallybook spots fail to load', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      rallybookSpotsOverride: stampRallybookSpotsProvider.overrideWith(
        (ref) => Future<List<RallybookSpot>?>.error(
          Exception('network unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('패스포트  2/29'), findsOneWidget);
    expect(find.text('여행할 명소를 골라보세요'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stamp-next-target-error')),
      findsNothing,
    );
  });

  testWidgets('shows a loading indicator while stamp tour is loading', (
    tester,
  ) async {
    final completer = Completer<StampBook?>();

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) => completer.future),
    );

    expect(find.text('랠리북'), findsNothing);
    expect(find.text('감자가 길을 찾는 중이에요'), findsOneWidget);
    expect(find.text('강원도 스탬프 지도를 준비하고 있어요'), findsOneWidget);
  });

  testWidgets('shows an error and retry action when stamp tour loading fails', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) => Future<StampBook?>.error(Exception('network unavailable')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsNothing);
    expect(find.text('스탬프 투어를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('prompts signed-out users to log in', (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => null),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 후 스탬프 투어를 확인할 수 있어요.'), findsOneWidget);
  });

  testWidgets('claims an available stamp reward from the stamp tour', (
    tester,
  ) async {
    final repository = _ClaimStampRepository();
    final controller = StampRewardClaimController(
      repository,
      onStampBookRefresh: () {},
      onCouponListRefresh: () {},
      onRewardHistoryRefresh: () {},
    );

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(acquiredCount: 6, claimableTargetCount: 6),
      ),
      additionalOverrides: [
        stampRewardClaimProvider.overrideWith((ref) => controller),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stamp-reward-claim-card')),
      findsOneWidget,
    );
    expect(find.text('6개 스탬프 달성!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stamp-reward-claim-button')));
    await tester.pumpAndSettle();

    expect(repository.requestedTargetCount, 6);
    expect(find.text('강원 감자 할인권을 받았어요.'), findsOneWidget);
  });

  testWidgets('disables reward claim while the request is pending', (
    tester,
  ) async {
    final completer = Completer<StampRewardClaimResult>();
    final repository = _ClaimStampRepository(completer: completer);
    final controller = StampRewardClaimController(
      repository,
      onStampBookRefresh: () {},
      onCouponListRefresh: () {},
      onRewardHistoryRefresh: () {},
    );

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(acquiredCount: 6, claimableTargetCount: 6),
      ),
      additionalOverrides: [
        stampRewardClaimProvider.overrideWith((ref) => controller),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stamp-reward-claim-button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('stamp-reward-claim-button')),
    );
    expect(button.onPressed, isNull);
    expect(repository.claimCount, 1);

    completer.complete(_claimResult);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the server message when reward claim fails', (
    tester,
  ) async {
    final repository = _ClaimStampRepository(
      error: const ApiException(message: '이미 수령한 보상입니다.'),
    );
    final controller = StampRewardClaimController(
      repository,
      onStampBookRefresh: () {},
      onCouponListRefresh: () {},
      onRewardHistoryRefresh: () {},
    );

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(
          acquiredCount: 6,
          claimableTargetCount: 6,
        ),
      ),
      additionalOverrides: [
        stampRewardClaimProvider.overrideWith((ref) => controller),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stamp-reward-claim-button')));
    await tester.pumpAndSettle();

    expect(find.text('이미 수령한 보상입니다.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Override override,
  Override? rallybookSpotsOverride,
  List<Override> additionalOverrides = const [],
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        override,
        rallybookSpotsOverride ??
            stampRallybookSpotsProvider.overrideWith(
              (ref) async => const <RallybookSpot>[],
            ),
        ...additionalOverrides,
      ],
      child: const MaterialApp(home: StampBookScreen()),
    ),
  );
}

const _rallybookSpots = <RallybookSpot>[
  RallybookSpot(
    spotId: 101,
    spotName: '정선 5일장',
    cityName: '정선군',
    category: 'POTATO_MARKET',
    latitude: 37.3805311,
    longitude: 128.6647911,
    address: '강원특별자치도 정선군',
    imageUrl: null,
  ),
  RallybookSpot(
    spotId: 102,
    spotName: '남이섬',
    cityName: '춘천시',
    category: 'POTATO_TOUR',
    latitude: 37.7962651,
    longitude: 127.5254892,
    address: '강원특별자치도 춘천시 남이섬길 1 남이섬',
    imageUrl: null,
  ),
  RallybookSpot(
    spotId: 103,
    spotName: '소양강 스카이워크',
    cityName: '춘천시',
    category: 'POTATO_TOUR',
    latitude: 37.8932774,
    longitude: 127.7236633,
    address: '강원특별자치도 춘천시 영서로 2663',
    imageUrl: null,
  ),
];

const _nearbyRallybookSpots = <RallybookSpot>[
  RallybookSpot(
    spotId: 201,
    spotName: '가까운 장소 A',
    cityName: '춘천시',
    category: 'POTATO_TOUR',
    latitude: 37.8932774,
    longitude: 127.7236633,
    address: '강원특별자치도 춘천시 가까운 길 1',
    imageUrl: null,
  ),
  RallybookSpot(
    spotId: 202,
    spotName: '가까운 장소 B',
    cityName: '춘천시',
    category: 'POTATO_TOUR',
    latitude: 37.9932774,
    longitude: 127.8236633,
    address: '강원특별자치도 춘천시 가까운 길 2',
    imageUrl: null,
  ),
];

Future<void> _tapMapMarker(WidgetTester tester, int spotId) async {
  await tester.tapAt(
    tester.getCenter(
      find.byKey(ValueKey('rallybook-spot-marker-$spotId')),
    ),
  );
}

StampBook _stampBook({
  int acquiredCount = 2,
  int? claimableTargetCount,
}) {
  final passportSpots = <({String cityName, String spotName})>[
    (cityName: '정선군', spotName: '정선 5일장'),
    (cityName: '춘천시', spotName: '남이섬'),
    (cityName: '춘천시', spotName: '소양강 스카이워크'),
    for (var index = 3; index < 29; index++)
      (cityName: '시군 $index', spotName: '관광지 ${index + 1}'),
  ];

  return StampBook(
    progress: StampProgress(
      totalCount: passportSpots.length,
      acquiredCount: acquiredCount,
      stamps: [
        for (var index = 0; index < passportSpots.length; index++)
          RallybookStamp(
            stampId: index + 1,
            spotId: 101 + index,
            cityName: passportSpots[index].cityName,
            stampName: passportSpots[index].spotName,
            stampImage: null,
            acquired: index < acquiredCount,
            acquiredAt: index < acquiredCount
                ? DateTime.parse('2026-06-30T00:00:00Z')
                : null,
          ),
      ],
    ),
    nextReward: NextStampReward(
      acquiredCount: acquiredCount,
      nextTargetCount: 12,
      remainingCount: 4,
      completed: false,
      claimable: claimableTargetCount != null,
      claimableTargetCount: claimableTargetCount,
    ),
  );
}

class _ClaimStampRepository extends StampRepository {
  _ClaimStampRepository({this.completer, this.error}) : super(dio: Dio());

  final Completer<StampRewardClaimResult>? completer;
  final Object? error;
  int claimCount = 0;
  int? requestedTargetCount;

  @override
  Future<StampRewardClaimResult> claimReward(
    StampRewardClaimRequest request,
  ) async {
    claimCount += 1;
    requestedTargetCount = request.targetCount;
    final claimError = error;
    if (claimError != null) {
      throw claimError;
    }
    final pendingResult = completer;
    if (pendingResult != null) {
      return pendingResult.future;
    }
    return _claimResult;
  }
}

final _claimResult = StampRewardClaimResult(
  targetCount: 6,
  rewardHistoryId: 10,
  userCouponId: 21,
  couponName: '강원 감자 할인권',
  expiresAt: DateTime.parse('2026-09-20T00:00:00Z'),
);
