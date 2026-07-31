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
  testWidgets('renders API rallybook progress, city stamps, and next reward', (
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

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('수집률'), findsOneWidget);
    expect(find.text('8 / 18'), findsOneWidget);
    expect(find.text('12개 달성까지 4개 남았어요'), findsOneWidget);
    expect(find.text('다음 목표'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('평창 감자 체험장'), findsOneWidget);
    expect(find.text('시군별 스탬프'), findsOneWidget);
    expect(find.text('강릉시'), findsOneWidget);
    expect(find.text('정선군'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -850));
    await tester.pumpAndSettle();

    expect(find.text('철원군'), findsOneWidget);
    expect(find.text('12개 달성 시 지역쿠폰 지급'), findsOneWidget);
    expect(find.text('앞으로 4개만 더 모으면 받을 수 있어요.'), findsOneWidget);
  });

  testWidgets('opens the selected next target detail', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('stamp-next-target-101')));
    await tester.pumpAndSettle();

    expect(find.text('상세 101'), findsOneWidget);
  });

  testWidgets('keeps rallybook visible when next target loading fails', (
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

    expect(find.text('8 / 18'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stamp-next-target-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stamp-next-target-retry')),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading indicator while rallybook is loading', (
    tester,
  ) async {
    final completer = Completer<StampBook?>();

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) => completer.future),
    );

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error and retry action when rallybook loading fails', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) => Future<StampBook?>.error(Exception('network unavailable')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('랠리북을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('shows completion copy after all city stamps are acquired', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(acquiredCount: 18, completed: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -850));
    await tester.pumpAndSettle();

    expect(find.text('18개 시군 랠리를 모두 완주했어요.'), findsOneWidget);
  });

  testWidgets('hides the claim button for a legacy reward status', (
    tester,
  ) async {
    final legacyReward = NextStampReward.fromJson(const {
      'acquiredCount': 8,
      'nextTargetCount': 12,
      'remainingCount': 4,
      'completed': false,
    });
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(reward: legacyReward),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stamp-reward-claim-button')),
      findsNothing,
    );
    expect(find.text('12개 달성 시 지역쿠폰 지급'), findsOneWidget);
  });

  testWidgets('shows the lowest claimable reward before completion copy', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(
          acquiredCount: 18,
          completed: true,
          claimable: true,
          claimableTargetCount: 6,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6개 달성 보상을 받을 수 있어요'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('받을 수 있는 보상'), findsOneWidget);
    expect(find.text('6개 달성 보상이 준비됐어요.'), findsOneWidget);
    expect(find.text('6개 보상 받기'), findsOneWidget);
    expect(find.text('18개 시군 랠리를 모두 완주했어요.'), findsNothing);
  });

  testWidgets(
    'disables reward claim while pending and shows success feedback',
    (tester) async {
      final completer = Completer<StampRewardClaimResult>();
      final repository = _PendingClaimStampRepository(completer);
      await _pumpScreen(
        tester,
        override: stampBookProvider.overrideWith(
          (ref) async => _stampBook(claimable: true, claimableTargetCount: 6),
        ),
        additionalOverrides: [
          stampRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final claimButton = find.byKey(
        const ValueKey('stamp-reward-claim-button'),
      );
      await tester.tap(claimButton);
      await tester.pump();

      expect(repository.claimCount, 1);
      expect(repository.requestedTargetCount, 6);
      expect(find.text('보상 받는 중...'), findsOneWidget);
      expect(tester.widget<FilledButton>(claimButton).onPressed, isNull);

      completer.complete(_claimResult);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('보상 수령이 완료됐어요. 쿠폰함에서 확인해 주세요.'), findsOneWidget);
    },
  );

  testWidgets('shows the Korean API error when reward claim fails', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(claimable: true, claimableTargetCount: 6),
      ),
      additionalOverrides: [
        stampRepositoryProvider.overrideWithValue(
          _FailingClaimStampRepository(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stamp-reward-claim-button')));
    await tester.pumpAndSettle();

    expect(find.text('이미 수령한 스탬프 보상입니다.'), findsOneWidget);
  });

  testWidgets('prompts signed-out users to log in', (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => null),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 후 랠리북을 확인할 수 있어요.'), findsOneWidget);
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
  bool completed = false,
  bool claimable = false,
  int? claimableTargetCount,
  NextStampReward? reward,
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
    nextReward:
        reward ??
        NextStampReward(
          acquiredCount: acquiredCount,
          nextTargetCount: completed ? null : 12,
          remainingCount: completed ? 0 : 4,
          completed: completed,
          claimable: claimable,
          claimableTargetCount: claimableTargetCount,
        ),
  );
}

class _PendingClaimStampRepository extends StampRepository {
  _PendingClaimStampRepository(this.completer) : super(dio: Dio());

  final Completer<StampRewardClaimResult> completer;
  int claimCount = 0;
  int? requestedTargetCount;

  @override
  Future<StampRewardClaimResult> claimReward(
    StampRewardClaimRequest request,
  ) async {
    claimCount += 1;
    requestedTargetCount = request.targetCount;
    return completer.future;
  }
}

class _FailingClaimStampRepository extends StampRepository {
  _FailingClaimStampRepository() : super(dio: Dio());

  @override
  Future<StampRewardClaimResult> claimReward(StampRewardClaimRequest request) {
    throw const ApiException(message: '이미 수령한 스탬프 보상입니다.', statusCode: 409);
  }
}

final _claimResult = StampRewardClaimResult(
  targetCount: 6,
  rewardHistoryId: 10,
  userCouponId: 21,
  couponName: '강원 감자 제휴점 3,000원 할인권',
  expiresAt: DateTime.parse('2026-08-16T00:00:00Z'),
);
