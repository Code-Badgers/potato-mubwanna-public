import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/feature_tour/data/feature_tour_status_store.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_definitions.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_host.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_overlay.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_targets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesFeatureTourStatusStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesFeatureTourStatusStore.resetInProcessForTesting();
    });

    test('stores completion independently for each page tour', () async {
      const store = SharedPreferencesFeatureTourStatusStore();

      await store.markCompleted('map-v2');

      expect(await store.hasCompleted('map-v2'), isTrue);
      expect(await store.hasCompleted('stamp-v2'), isFalse);

      await store.markCompleted('stamp-v2');

      expect(await store.hasCompleted('map-v2'), isTrue);
      expect(await store.hasCompleted('stamp-v2'), isTrue);
    });

    test('keeps compatibility with the legacy completion key', () async {
      SharedPreferences.setMockInitialValues({
        'completedFeatureTourVersion': '1',
      });
      const store = SharedPreferencesFeatureTourStatusStore();

      expect(await store.hasCompleted('1'), isTrue);
      expect(await store.hasCompleted('map-v2'), isFalse);
    });
  });

  group('FeatureTourDefinitions', () {
    test('covers page-specific interaction targets', () {
      expect(
        FeatureTourDefinitions.map,
        contains(
          isA<FeatureTourStep>().having(
            (step) => step.targetKey,
            'targetKey',
            same(FeatureTourTargets.mapCourseCard),
          ),
        ),
      );
      expect(
        FeatureTourDefinitions.map,
        contains(
          isA<FeatureTourStep>().having(
            (step) => step.targetKey,
            'targetKey',
            same(FeatureTourTargets.mapGoodNowCard),
          ),
        ),
      );
      expect(
        FeatureTourDefinitions.map
            .firstWhere(
                (step) => step.targetKey == FeatureTourTargets.spotSheetHandle)
            .advanceType,
        CoachMarkAdvanceType.swipeUp,
      );
      final mapMarkerStep = FeatureTourDefinitions.map.firstWhere(
        (step) => step.targetKey == FeatureTourTargets.mapMarker,
      );
      expect(
        mapMarkerStep.spotlightTargetKey,
        same(FeatureTourTargets.mapSelectedSpotCard),
      );
      expect(
        mapMarkerStep.interactionTargetKey,
        same(FeatureTourTargets.mapMarker),
      );
      expect(
        FeatureTourDefinitions.stamp.map((step) => step.targetKey),
        contains(FeatureTourTargets.passportButton),
      );
      expect(
        FeatureTourDefinitions.potato.map((step) => step.targetKey),
        containsAll([
          FeatureTourTargets.potatoInfo,
          FeatureTourTargets.representativePotato,
        ]),
      );
      expect(
        FeatureTourDefinitions.potato
            .where(
              (step) =>
                  step.targetKey == FeatureTourTargets.potatoInfo ||
                  step.targetKey == FeatureTourTargets.representativePotato,
            )
            .every(
              (step) =>
                  step.advanceType == CoachMarkAdvanceType.navigationResult,
            ),
        isTrue,
      );
      expect(
        FeatureTourDefinitions.potato.map((step) => step.targetKey),
        isNot(contains(FeatureTourTargets.potatoSteps)),
      );
      expect(
        FeatureTourDefinitions.spot.map((step) => step.targetKey),
        containsAll([
          FeatureTourTargets.audioPlay,
          FeatureTourTargets.visitVerify,
        ]),
      );
      expect(
        FeatureTourDefinitions.myPage.single.targetKey,
        same(FeatureTourTargets.myPageTravelRecord),
      );
      expect(
        FeatureTourDefinitions.spot.every(
          (step) => step.advanceType == CoachMarkAdvanceType.targetTap,
        ),
        isTrue,
      );
      expect(
        FeatureTourDefinitions.passport.single.description,
        contains('스탬프'),
      );
    });
  });

  group('FeatureTourController', () {
    test('waits for a navigation result before advancing a route step',
        () async {
      var completed = false;
      final controller = FeatureTourController(
        tourId: 'potato-v4',
        steps: [
          FeatureTourStep(
            targetKey: GlobalKey(),
            title: '정보 보기',
            description: '상세 정보를 확인해보세요.',
            advanceType: CoachMarkAdvanceType.navigationResult,
          ),
          FeatureTourStep(
            targetKey: GlobalKey(),
            title: '대표 감자',
            description: '대표 감자를 바꿔보세요.',
          ),
        ],
        onCompleted: () async {
          completed = true;
        },
      );
      addTearDown(controller.dispose);

      controller.activate();
      controller.completeTarget(controller.currentStep.targetKey);
      expect(controller.stepIndex, 0);
      expect(controller.isActive, isTrue);

      controller.completeNavigation();

      expect(controller.stepIndex, 1);
      expect(controller.isActive, isTrue);
      expect(completed, isFalse);
    });
  });

  group('FeatureTourHost', () {
    late _FakeFeatureTourStatusStore store;

    setUp(() {
      store = _FakeFeatureTourStatusStore();
    });

    testWidgets('advances a target step only after the target is tapped',
        (tester) async {
      final introKey = GlobalKey();
      final actionKey = GlobalKey();

      await tester.pumpWidget(
        _tourApp(
          store: store,
          tourId: 'map-v2',
          steps: [
            FeatureTourStep(
              targetKey: introKey,
              title: '지도 둘러보기',
              description: '지도의 주요 기능을 소개합니다.',
            ),
            FeatureTourStep(
              targetKey: actionKey,
              title: '직접 눌러보기',
              description: '강조된 버튼을 눌러 다음 단계로 넘어갑니다.',
              advanceType: CoachMarkAdvanceType.targetTap,
              interactionHint: '버튼을 눌러보세요',
            ),
          ],
          child: _TourPage(
            introKey: introKey,
            actionKey: actionKey,
          ),
        ),
      );
      await _settleTour(tester);

      expect(find.text('지도 둘러보기'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('다음'));
      await _settleTour(tester);

      expect(find.text('직접 눌러보기'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tour-target-action')));
      await _settleTour(tester);

      expect(find.text('직접 눌러보기'), findsNothing);
      expect(store.completedIds, contains('map-v2'));
    });

    testWidgets('automatically scrolls an offscreen target before showing it',
        (tester) async {
      final scrollController = ScrollController();
      final targetKey = GlobalKey();

      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _tourApp(
          store: store,
          tourId: 'potato-v2',
          steps: [
            FeatureTourStep(
              targetKey: targetKey,
              title: '감자밭 돌보기',
              description: '화면 아래 기능도 이어서 확인할 수 있어요.',
            ),
          ],
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 900),
                Container(
                  key: targetKey,
                  height: 80,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );

      await _settleTour(tester);

      expect(scrollController.offset, greaterThan(0));
      expect(find.text('감자밭 돌보기'), findsOneWidget);
    });

    testWidgets('completing one page tour does not hide another page tour',
        (tester) async {
      final mapKey = GlobalKey();
      final stampKey = GlobalKey();

      await tester.pumpWidget(
        _tourApp(
          store: store,
          tourId: 'map-v2',
          steps: [
            FeatureTourStep(
              targetKey: mapKey,
              title: '지도 투어',
              description: '지도를 살펴보세요.',
            ),
          ],
          child: _TourPage(introKey: mapKey),
        ),
      );
      await _settleTour(tester);
      await tester.tap(find.text('확인'));
      await _settleTour(tester);

      await tester.pumpWidget(
        _tourApp(
          store: store,
          tourId: 'stamp-v2',
          steps: [
            FeatureTourStep(
              targetKey: stampKey,
              title: '스탬프 투어',
              description: '스탬프를 모아보세요.',
            ),
          ],
          child: _TourPage(introKey: stampKey),
        ),
      );
      await _settleTour(tester);

      expect(find.text('스탬프 투어'), findsOneWidget);
      expect(store.completedIds, contains('map-v2'));
      expect(store.completedIds, isNot(contains('stamp-v2')));
    });
  });
}

Widget _tourApp({
  required _FakeFeatureTourStatusStore store,
  required String tourId,
  required List<FeatureTourStep> steps,
  required Widget child,
}) {
  return MaterialApp(
    home: FeatureTourHost(
      tourId: tourId,
      steps: steps,
      statusStore: store,
      child: child,
    ),
  );
}

Future<void> _settleTour(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
  // Target preparation includes a short post-scroll layout stabilization.
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

class _TourPage extends StatelessWidget {
  const _TourPage({required this.introKey, this.actionKey});

  final GlobalKey introKey;
  final GlobalKey? actionKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(key: introKey, height: 100, width: 200),
        if (actionKey != null)
          KeyedSubtree(
            key: actionKey,
            child: ElevatedButton(
              key: const ValueKey('tour-target-action'),
              onPressed: () {
                FeatureTourScope.maybeOf(context)?.completeTarget(actionKey!);
              },
              child: const Text('대상 버튼'),
            ),
          ),
      ],
    );
  }
}

class _FakeFeatureTourStatusStore implements FeatureTourStatusStore {
  final completedIds = <String>{};

  @override
  Future<bool> hasCompleted(String version) async {
    return completedIds.contains(version);
  }

  @override
  Future<void> markCompleted(String version) async {
    completedIds.add(version);
  }
}
