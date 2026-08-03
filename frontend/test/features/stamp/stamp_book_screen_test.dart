import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/features/stamp/application/stamp_book_controller.dart';
import 'package:potato_mubwanna/features/stamp/domain/stamp_book.dart';
import 'package:potato_mubwanna/features/stamp/presentation/screen/stamp_book_screen.dart';

void main() {
  testWidgets('renders a map-first stamp tour and selected city card', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      nextTargetsOverride: stampNextTargetsProvider.overrideWith(
        (ref) async => _nextTargets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsNothing);
    expect(find.text('스탬프 투어'), findsNothing);
    expect(find.text('강원도 지도 위에 도장을 모아보세요'), findsNothing);
    expect(find.text('8/18'), findsOneWidget);
    expect(find.text('12개 달성까지 4개 남았어요'), findsNothing);
    expect(find.text('다음 스탬프 추천'), findsNothing);
    expect(find.text('지도의 시군을 눌러 스탬프 상태를 확인해보세요.'), findsNothing);
    expect(find.text('안목해변'), findsOneWidget);
    expect(find.text('여행할 지역을 골라보세요'), findsOneWidget);
    expect(find.text('지역을 선택하면 스탬프를 찍을 장소가 나타나요.'), findsOneWidget);
    expect(find.text('스탬프 찍기'), findsNothing);

    await tester.tap(find.text('정선 5일장'));
    await tester.pumpAndSettle();

    expect(find.text('여행할 지역을 골라보세요'), findsNothing);
    expect(find.text('정선 5일장'), findsWidgets);
    expect(find.text('정선 · 스탬프 완료'), findsOneWidget);
    expect(find.text('대표 스팟 보기'), findsNothing);
    expect(find.text('오디오 준비중'), findsNothing);
    expect(find.text('스탬프 준비중'), findsNothing);
    expect(find.text('스탬프 찍기'), findsOneWidget);
    expect(find.text('투어 진행률'), findsNothing);
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
          stampNextTargetsProvider.overrideWith((ref) async => _nextTargets),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('정선 5일장'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('스탬프 찍기'));
    await tester.pumpAndSettle();

    expect(find.text('상세 101'), findsOneWidget);
  });

  testWidgets('renders city stamp card grid', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stampBookProvider.overrideWith((ref) async => _stampBook()),
        ],
        child: const MaterialApp(home: CityStampGridScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('시군별 스탬프'), findsOneWidget);
    expect(find.text('강원 18개 시군 수집률'), findsOneWidget);
    expect(find.text('8 / 18'), findsOneWidget);
    expect(find.text('강릉시'), findsOneWidget);
    expect(find.text('정선군'), findsOneWidget);
    expect(find.text('완료'), findsWidgets);
    expect(find.text('미획득'), findsWidgets);
  });

  testWidgets('keeps stamp tour visible when next target loading fails', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
      nextTargetsOverride: stampNextTargetsProvider.overrideWith(
        (ref) => Future<List<StampNextTarget>?>.error(
          Exception('network unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('안목해변'), findsOneWidget);
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Override override,
  Override? nextTargetsOverride,
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
        nextTargetsOverride ??
            stampNextTargetsProvider.overrideWith(
              (ref) async => const <StampNextTarget>[],
            ),
        ...additionalOverrides,
      ],
      child: const MaterialApp(home: StampBookScreen()),
    ),
  );
}

const _nextTargets = <StampNextTarget>[
  StampNextTarget(
    spotId: 101,
    spotName: '정선 5일장',
    cityName: '정선군',
    category: 'POTATO_MARKET',
    address: '강원특별자치도 정선군',
    imageUrl: null,
  ),
  StampNextTarget(
    spotId: 102,
    spotName: '평창 감자 체험장',
    cityName: '평창군',
    category: 'POTATO_EXPERIENCE',
    address: '강원특별자치도 평창군',
    imageUrl: null,
  ),
];

StampBook _stampBook({
  int acquiredCount = 8,
}) {
  const cityNames = [
    '강릉시',
    '정선군',
    '평창군',
    '춘천시',
    '속초시',
    '홍천군',
    '횡성군',
    '영월군',
    '원주시',
    '동해시',
    '태백시',
    '삼척시',
    '양양군',
    '고성군',
    '인제군',
    '양구군',
    '화천군',
    '철원군',
  ];

  return StampBook(
    progress: StampProgress(
      totalCount: cityNames.length,
      acquiredCount: acquiredCount,
      stamps: [
        for (var index = 0; index < cityNames.length; index++)
          RallybookStamp(
            stampId: index + 1,
            cityName: cityNames[index],
            stampName: '감자 ${index + 1}',
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
      claimable: false,
      claimableTargetCount: null,
    ),
  );
}
