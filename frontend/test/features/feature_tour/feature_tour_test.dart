import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/features/feature_tour/data/feature_tour_status_store.dart';
import 'package:potato_mubwanna/shared/widgets/navigation/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesFeatureTourStatusStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('stores and reads the completed version', () async {
      const store = SharedPreferencesFeatureTourStatusStore();

      expect(
        await store.hasCompleted(
          SharedPreferencesFeatureTourStatusStore.currentVersion,
        ),
        isFalse,
      );

      await store.markCompleted(
        SharedPreferencesFeatureTourStatusStore.currentVersion,
      );

      expect(
        await store.hasCompleted(
          SharedPreferencesFeatureTourStatusStore.currentVersion,
        ),
        isTrue,
      );
    });

    test('shows a newer tour version as incomplete', () async {
      const store = SharedPreferencesFeatureTourStatusStore();

      await store.markCompleted('1');

      expect(await store.hasCompleted('2'), isFalse);
    });
  });

  group('MainShell feature tour', () {
    late _FakeFeatureTourStatusStore store;

    setUp(() {
      store = _FakeFeatureTourStatusStore();
    });

    testWidgets('shows the first step and can be skipped', (tester) async {
      await _pumpShell(tester, store);

      expect(find.text('강원도에서 오늘 갈 곳을 찾아보세요'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);

      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      expect(find.text('강원도에서 오늘 갈 곳을 찾아보세요'), findsNothing);
      expect(store.completed, isTrue);
      expect(store.completedVersion, '1');
    });

    testWidgets('moves through all five steps and persists completion',
        (tester) async {
      await _pumpShell(tester, store);

      expect(find.text('1 / 5'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('가고 싶은 곳은 내 동선에 담아보세요'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget);

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('직접 방문하고 스탬프를 모아요'), findsOneWidget);

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('여행하며 나만의 감자를 키워보세요'), findsOneWidget);

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('점순이와 여행 미션도 즐겨보세요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('점순이와 여행 미션도 즐겨보세요'), findsNothing);
      expect(store.completed, isTrue);
    });

    testWidgets('does not show after the current version is completed',
        (tester) async {
      store.completed = true;

      await _pumpShell(tester, store);

      expect(find.text('강원도에서 오늘 갈 곳을 찾아보세요'), findsNothing);
    });
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  _FakeFeatureTourStatusStore store,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/main/map',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(
          featureTourStatusStore: store,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/main/map',
            builder: (context, state) => const SizedBox(
              key: ValueKey('tour-map-screen'),
            ),
          ),
          GoRoute(
            path: '/main/stamps',
            builder: (context, state) => const SizedBox(
              key: ValueKey('tour-stamp-screen'),
            ),
          ),
          GoRoute(
            path: '/main/potatoes',
            builder: (context, state) => const SizedBox(
              key: ValueKey('tour-potato-screen'),
            ),
          ),
          GoRoute(
            path: '/main/missions',
            builder: (context, state) => const SizedBox(
              key: ValueKey('tour-mission-screen'),
            ),
          ),
          GoRoute(
            path: '/main/mypage',
            builder: (context, state) => const SizedBox(
              key: ValueKey('tour-mypage-screen'),
            ),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

class _FakeFeatureTourStatusStore implements FeatureTourStatusStore {
  bool completed = false;
  String? completedVersion;

  @override
  Future<bool> hasCompleted(String version) async => completed;

  @override
  Future<void> markCompleted(String version) async {
    completed = true;
    completedVersion = version;
  }
}
