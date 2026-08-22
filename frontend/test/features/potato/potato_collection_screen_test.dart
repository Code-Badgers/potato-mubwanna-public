import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/potato/application/potato_collection_controller.dart';
import 'package:potato_mubwanna/features/potato/data/potato_repository.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/potato/presentation/screen/potato_collection_screen.dart';

void main() {
  testWidgets('renders potato representative summary only on the main view', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('대표 감자'), findsNothing);
    expect(find.text('곤드레감자'), findsWidgets);
    expect(find.text('오늘 감자걸음'), findsOneWidget);
    expect(find.text('7,842 / 10,000걸음'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('81 / 100'), findsOneWidget);
    expect(find.text('64 / 100'), findsOneWidget);
    expect(find.text('93 / 100'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '정보 보기'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '대표 감자 변경'), findsOneWidget);
    expect(find.text('나의 감자 도감'), findsNothing);
    expect(find.text('미획득'), findsNothing);
  });

  testWidgets('opens representative potato detail from the main card', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    final detailButton = find.widgetWithText(OutlinedButton, '정보 보기');
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('곤드레감자'), findsWidgets);
    expect(find.text('감자 이야기'), findsOneWidget);
    expect(find.text('획득 기록'), findsOneWidget);
    expect(find.text('성장 진행'), findsOneWidget);
    expect(find.text('대표 감자로 설정'), findsNothing);
  });

  testWidgets('renders reward-only potato code with mapped local asset', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith(
          (ref) async => _rewardOnlyCollection(),
        ),
      ],
    );
    await tester.pumpAndSettle();

    final mappedAsset = find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/characters/potatoes/food_rest_stop_whole_potato.png';
    });

    expect(find.text('일반 씨앗감자'), findsWidgets);
    expect(mappedAsset, findsWidgets);
  });

  testWidgets('uses the beginner potato consistently before first acquisition',
      (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith(
          (ref) async => _unacquiredCollection(),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('새싹 감자'), findsWidgets);
    expect(find.text('강릉 감자빵'), findsNothing);

    final detailButton = find.widgetWithText(OutlinedButton, '정보 보기');
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('#000'), findsOneWidget);
    expect(
      find.text('아직 여행을 시작하지 않은 작은 감자예요. 첫 스탬프를 찍으면 도감 이야기가 하나씩 열립니다.'),
      findsWidgets,
    );
  });

  testWidgets('opens the potato collection sheet from representative action', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '대표 감자 변경'));
    await tester.pumpAndSettle();

    expect(find.text('나의 감자 도감'), findsOneWidget);
    expect(find.textContaining('감자를 누르면'), findsNothing);
    expect(find.text('하지감자'), findsOneWidget);
    expect(find.text('???'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '상세'), findsNothing);
    expect(find.widgetWithText(TextButton, '힌트'), findsNothing);
    expect(find.text('대표 감자로 설정'), findsNothing);
  });

  testWidgets('opens a picker item detail without changing representative', (
    tester,
  ) async {
    final repository = _FakePotatoRepository();

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '대표 감자 변경'));
    await tester.pumpAndSettle();
    final lockedPotato = find.text('???');
    await tester.ensureVisible(lockedPotato);
    await tester.tap(lockedPotato);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('아직 만나지 못한 감자'), findsWidgets);
    expect(find.text('감자 이야기'), findsOneWidget);
    expect(find.text('획득 기록'), findsOneWidget);
    expect(repository.updatedPotatoId, isNull);
  });

  testWidgets('shows a signed out state for guests', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [potatoCollectionProvider.overrideWith((ref) async => null)],
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 후 수집한 감자를 확인할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('updates representative potato from the picker', (tester) async {
    final repository = _FakePotatoRepository();

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '대표 감자 변경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('하지감자').last);
    await tester.pumpAndSettle();

    expect(repository.updatedPotatoId, '1');
    expect(find.text('대표 감자를 하지감자로 변경했어요.'), findsOneWidget);
  });

  testWidgets('persists potato care and shows the growth distance', (
    tester,
  ) async {
    final repository = _FakePotatoRepository();

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('쓰다듬기'));
    await tester.pumpAndSettle();

    expect(repository.interactionAction, PotatoInteractionAction.pat);
    expect(find.text('기분이 좋아졌어요. 성장 거리 50m 추가!'), findsOneWidget);
  });

  testWidgets('sends the snack care action to the server', (tester) async {
    final repository = _FakePotatoRepository();

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('간식 주기'));
    await tester.tap(find.text('간식 주기'));
    await tester.pumpAndSettle();

    expect(repository.interactionAction, PotatoInteractionAction.snack);
    expect(find.text('간식을 먹었어요. 성장 거리 50m 추가!'), findsOneWidget);
  });

  testWidgets('shows the server message when potato care is rejected', (
    tester,
  ) async {
    final repository = _FakePotatoRepository(
      interactionError: const ApiException(
        message: '쓰다듬기는 30분 후 다시 할 수 있습니다.',
        statusCode: 429,
      ),
    );

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('쓰다듬기'));
    await tester.pumpAndSettle();

    expect(find.text('쓰다듬기는 30분 후 다시 할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('shows a level-up dialog after the latest collection loads', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      growthResult: const PotatoGrowthResult(
        potatoId: '2',
        potatoName: '곤드레감자',
        previousLevel: 2,
        currentLevel: 3,
        leveledUp: true,
        fullyGrown: false,
      ),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('곤드레감자가 성장했어요!'), findsOneWidget);
    expect(find.text('Lv.2에서 Lv.3으로 성장했어요.'), findsOneWidget);
    expect(find.text('도감에서 확인'), findsOneWidget);
  });

  testWidgets('shows a distinct dialog when the potato is fully grown', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      growthResult: const PotatoGrowthResult(
        potatoId: '2',
        potatoName: '곤드레감자',
        previousLevel: 4,
        currentLevel: 5,
        leveledUp: true,
        fullyGrown: true,
      ),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('곤드레감자가 완전히 자랐어요!'), findsOneWidget);
    expect(find.text('최종 성장 단계 Lv.5에 도달했어요.'), findsOneWidget);
  });

  testWidgets('does not show growth feedback without a level-up', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      growthResult: const PotatoGrowthResult(
        potatoId: '2',
        potatoName: '곤드레감자',
        previousLevel: 2,
        currentLevel: 2,
        leveledUp: false,
        fullyGrown: false,
      ),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('성장했어요!'), findsNothing);
    expect(find.text('나의 감자 도감'), findsNothing);
  });

  testWidgets(
    'pull to refresh reloads activity, collection, and summary once',
    (tester) async {
      var activitySyncCalls = 0;
      var collectionCalls = 0;
      var growthSummaryCalls = 0;

      await _pumpScreen(
        tester,
        activitySyncOverride: potatoActivitySyncProvider.overrideWith((
          ref,
        ) async {
          activitySyncCalls += 1;
          return null;
        }),
        growthSummaryOverride: potatoGrowthSummaryProvider.overrideWith((
          ref,
        ) async {
          growthSummaryCalls += 1;
          return _growthSummary();
        }),
        overrides: [
          potatoCollectionProvider.overrideWith((ref) async {
            collectionCalls += 1;
            return _collection();
          }),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      final refreshIndicator = tester.state<RefreshIndicatorState>(
        find.byType(RefreshIndicator),
      );
      unawaited(refreshIndicator.show());
      await tester.pumpAndSettle();

      expect(activitySyncCalls, 2);
      expect(collectionCalls, 2);
      expect(growthSummaryCalls, 2);
    },
  );

  testWidgets('resuming the app reloads potato data once', (tester) async {
    var activitySyncCalls = 0;
    var collectionCalls = 0;
    var growthSummaryCalls = 0;

    await _pumpScreen(
      tester,
      activitySyncOverride: potatoActivitySyncProvider.overrideWith((
        ref,
      ) async {
        activitySyncCalls += 1;
        return null;
      }),
      growthSummaryOverride: potatoGrowthSummaryProvider.overrideWith((
        ref,
      ) async {
        growthSummaryCalls += 1;
        return _growthSummary();
      }),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async {
          collectionCalls += 1;
          return _collection();
        }),
      ],
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(activitySyncCalls, 2);
    expect(collectionCalls, 2);
    expect(growthSummaryCalls, 2);
  });

  testWidgets('overlapping manual and resume refreshes share one request', (
    tester,
  ) async {
    var activitySyncCalls = 0;
    var collectionCalls = 0;
    var growthSummaryCalls = 0;
    final collectionRefresh = Completer<PotatoCollection?>();
    final growthSummaryRefresh = Completer<PotatoGrowthSummary?>();

    await _pumpScreen(
      tester,
      activitySyncOverride: potatoActivitySyncProvider.overrideWith((
        ref,
      ) async {
        activitySyncCalls += 1;
        return null;
      }),
      growthSummaryOverride: potatoGrowthSummaryProvider.overrideWith((
        ref,
      ) async {
        growthSummaryCalls += 1;
        if (growthSummaryCalls == 1) {
          return _growthSummary();
        }
        return growthSummaryRefresh.future;
      }),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async {
          collectionCalls += 1;
          if (collectionCalls == 1) {
            return _collection();
          }
          return collectionRefresh.future;
        }),
      ],
    );
    await tester.pumpAndSettle();

    final refreshIndicator = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(refreshIndicator.show());
    await tester.pump();
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(activitySyncCalls, 2);
    expect(collectionCalls, 2);
    expect(growthSummaryCalls, 2);

    collectionRefresh.complete(_collection());
    growthSummaryRefresh.complete(_growthSummary());
    await tester.pumpAndSettle();
  });

  testWidgets('shows refreshed growth feedback only once', (tester) async {
    var activitySyncCalls = 0;
    const growthResult = PotatoGrowthResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      previousLevel: 2,
      currentLevel: 3,
      leveledUp: true,
      fullyGrown: false,
    );

    await _pumpScreen(
      tester,
      activitySyncOverride: potatoActivitySyncProvider.overrideWith((
        ref,
      ) async {
        activitySyncCalls += 1;
        return activitySyncCalls == 1 ? null : growthResult;
      }),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    final refreshIndicator = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(refreshIndicator.show());
    await tester.pumpAndSettle();

    expect(find.text('곤드레감자가 성장했어요!'), findsOneWidget);
    await tester.tap(find.text('도감에서 확인'));
    await tester.pumpAndSettle();

    unawaited(refreshIndicator.show());
    await tester.pumpAndSettle();

    expect(activitySyncCalls, 3);
    expect(find.text('곤드레감자가 성장했어요!'), findsNothing);
  });

  testWidgets('does not refresh after the potato screen is disposed', (
    tester,
  ) async {
    var activitySyncCalls = 0;

    await _pumpScreen(
      tester,
      activitySyncOverride: potatoActivitySyncProvider.overrideWith((
        ref,
      ) async {
        activitySyncCalls += 1;
        return null;
      }),
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();
    expect(activitySyncCalls, 1);
    final screenState = tester.state(find.byType(PotatoCollectionScreen));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(screenState.mounted, isFalse);
    expect(activitySyncCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(activitySyncCalls, 1);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
  PotatoGrowthResult? growthResult,
  Override? activitySyncOverride,
  Override? growthSummaryOverride,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activitySyncOverride ??
            potatoActivitySyncProvider.overrideWith(
              (ref) async => growthResult,
            ),
        growthSummaryOverride ??
            potatoGrowthSummaryProvider.overrideWith(
              (ref) async => _growthSummary(),
            ),
        ...overrides,
      ],
      child: const MaterialApp(home: PotatoCollectionScreen()),
    ),
  );
}

class _FakePotatoRepository extends PotatoRepository {
  _FakePotatoRepository({this.interactionError}) : super(dio: Dio());

  final ApiException? interactionError;
  String? updatedPotatoId;
  PotatoInteractionAction? interactionAction;

  @override
  Future<PotatoRepresentativeResult> updateRepresentativePotato(
    String potatoId,
  ) async {
    updatedPotatoId = potatoId;
    return PotatoRepresentativeResult(potatoId: potatoId, representative: true);
  }

  @override
  Future<PotatoInteractionResult> interactWithRepresentativePotato(
    PotatoInteractionAction action,
  ) async {
    interactionAction = action;
    final error = interactionError;
    if (error != null) {
      throw error;
    }
    return PotatoInteractionResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      action: action,
      growthDistanceAdded: 50,
      cooldownSeconds: 1800,
      nextAvailableAt: DateTime.parse('2026-08-20T10:30:00Z'),
      careStatus: PotatoCareStatus(
        satiety: 100,
        moisture: 64,
        mood: 93,
        calculatedAt: DateTime.utc(2026, 8, 20, 10),
      ),
      growthResult: const PotatoGrowthResult(
        potatoId: '2',
        potatoName: '곤드레감자',
        previousLevel: 3,
        currentLevel: 3,
        leveledUp: false,
        fullyGrown: false,
      ),
    );
  }
}

PotatoGrowthSummary _growthSummary() {
  return const PotatoGrowthSummary(
    todaySteps: 7842,
    dailyStepGoal: 10000,
    weeklyDistanceKm: 28.4,
    monthlyDistanceKm: 116.8,
    remainingDistanceKmForRepresentative: 1.8,
  );
}

PotatoCollection _collection() {
  return PotatoCollection(
    totalCount: 3,
    acquiredCount: 2,
    items: [
      PotatoCollectionItem(
        id: '1',
        code: 'POTATO_HAJI_GANGNEUNG',
        name: '하지감자',
        region: '강릉시',
        rarity: PotatoRarity.common,
        description: '강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.',
        acquisitionHint: '강릉 감자 스팟 방문 인증',
        imageUrl: null,
        acquired: true,
        acquiredAt: DateTime.parse('2026-07-01T00:00:00Z'),
        level: 2,
        growthDistance: 1500,
        growthGoalDistance: 3000,
        representative: false,
        careStatus: PotatoCareStatus(
          satiety: 70,
          moisture: 70,
          mood: 70,
          calculatedAt: DateTime.parse('2026-08-20T10:00:00Z'),
        ),
      ),
      PotatoCollectionItem(
        id: '2',
        code: 'POTATO_GONDRE_JEONGSEON',
        name: '곤드레감자',
        region: '정선군',
        rarity: PotatoRarity.rare,
        description: '정선 장터와 곤드레 향토 음식 이야기를 품은 희귀 감자입니다.',
        acquisitionHint: '정선 5일장 미션 완료',
        imageUrl: null,
        acquired: true,
        acquiredAt: DateTime.parse('2026-07-02T00:00:00Z'),
        level: 3,
        growthDistance: 4200,
        growthGoalDistance: 4200,
        representative: true,
        careStatus: PotatoCareStatus(
          satiety: 81,
          moisture: 64,
          mood: 93,
          calculatedAt: DateTime.parse('2026-08-20T10:00:00Z'),
        ),
      ),
      const PotatoCollectionItem(
        id: '3',
        code: 'POTATO_LEGEND_PYEONGCHANG',
        name: '전설감자',
        region: '평창군',
        rarity: PotatoRarity.legendary,
        description: '강원 고랭지 여행을 오래 이어간 사용자에게 열리는 감자입니다.',
        acquisitionHint: '평창 희귀 미션 완료',
        imageUrl: null,
        acquired: false,
        acquiredAt: null,
        level: 0,
        growthDistance: 0,
        growthGoalDistance: 10000,
        representative: false,
      ),
    ],
  );
}

PotatoCollection _rewardOnlyCollection() {
  return PotatoCollection(
    totalCount: 1,
    acquiredCount: 1,
    items: [
      PotatoCollectionItem(
        id: '10',
        code: 'POTATO_COMMON_SEED',
        name: '일반 씨앗감자',
        region: '평창군',
        rarity: PotatoRarity.common,
        description: '대관령 여행길에서 만날 수 있는 기본 씨앗 감자입니다.',
        acquisitionHint: '대관령 양떼목장 방문 미션 완료',
        imageUrl: null,
        acquired: true,
        acquiredAt: DateTime.parse('2026-07-10T00:00:00Z'),
        level: 1,
        growthDistance: 600,
        growthGoalDistance: 3000,
        representative: true,
        careStatus: PotatoCareStatus(
          satiety: 70,
          moisture: 70,
          mood: 70,
          calculatedAt: DateTime.parse('2026-08-20T10:00:00Z'),
        ),
      ),
    ],
  );
}

PotatoCollection _unacquiredCollection() {
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
