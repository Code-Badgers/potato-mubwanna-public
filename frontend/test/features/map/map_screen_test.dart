import 'package:potato_mubwanna/shared/models/congestion_prediction.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
import 'package:potato_mubwanna/features/map/domain/spot_detail.dart';
import 'package:potato_mubwanna/features/map/domain/spot_recommendation.dart';
import 'package:potato_mubwanna/features/map/domain/travel_course_route_estimate.dart';
import 'package:potato_mubwanna/features/map/presentation/screen/map_screen.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_targets.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_definitions.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_host.dart';
import 'package:potato_mubwanna/features/feature_tour/presentation/feature_tour_overlay.dart';
import 'package:potato_mubwanna/features/feature_tour/data/feature_tour_status_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_mubwanna/shared/widgets/loading/potato_loading_view.dart';

void main() {
  testWidgets('map controls have names and fit a narrow large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => _spots),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: MapScreen(
          hasMapConfiguration: true,
          showFullMapInitially: true,
          mapViewBuilder: (_, __) => const SizedBox.expand(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('지도 홈으로 돌아가기'), findsOneWidget);
    expect(find.bySemanticsLabel('현재 위치로 이동'), findsOneWidget);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('full-map-home-button')))
            .height,
        greaterThanOrEqualTo(48));
    final category = find.bySemanticsLabel('전체');
    expect(tester.getSize(category).height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });
  for (final stampEnabled in [true, false]) {
    testWidgets('map visit entry respects stampEnabled=$stampEnabled',
        (tester) async {
      final spot = MapSpot.fromJson({
        'id': 1,
        'name': '테스트 장소',
        'stampEnabled': stampEnabled,
        'category': 'POTATO_TOUR',
        'latitude': 37.38,
        'longitude': 128.66,
      });
      final router = GoRouter(initialLocation: '/map', routes: [
        GoRoute(
            path: '/map',
            builder: (_, __) => const MapScreen(
                  hasMapConfiguration: true,
                  showFullMapInitially: true,
                )),
        GoRoute(
            path: '/spots/:spotId',
            builder: (_, state) => Scaffold(
                  body: Text('인증 장소 ${state.pathParameters['spotId']}'),
                )),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => [spot]),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ], child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('map-visit-verify-1'));
      if (stampEnabled) {
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('인증 장소 1'), findsOneWidget);
      } else {
        expect(button, findsNothing);
      }
    });
  }

  testWidgets('location button explains denied permission without closing map',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => 0,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => _spots),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: MaterialApp(
          home: MapScreen(
        hasMapConfiguration: true,
        showFullMapInitially: true,
        mapViewBuilder: (_, __) => const SizedBox.expand(),
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byKey(const ValueKey('full-map-locate-button')));
    await tester.pumpAndSettle();
    expect(find.text('현재 위치를 보려면 위치 권한을 허용해 주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('full-map-home-button')), findsOneWidget);
  });

  testWidgets(
      'recommendation groups use category fallback without swapping LOW',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => [_spots[0], _spots[1]]),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: const MaterialApp(home: MapScreen(hasMapConfiguration: true)),
    ));
    await tester.pumpAndSettle();
    final calm = find.byKey(const ValueKey('good-now-calm'));
    final hot = find.byKey(const ValueKey('good-now-hot'));
    final other = find.byKey(const ValueKey('good-now-other'));
    await tester.scrollUntilVisible(calm, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.descendant(of: calm, matching: find.text('감자 카페')),
        findsOneWidget);
    expect(
        find.descendant(of: hot, matching: find.text('감자 카페')), findsNothing);
    expect(find.descendant(of: hot, matching: find.text('정선 5일장')),
        findsOneWidget);
    expect(
        find.descendant(of: hot, matching: find.text('지금은 이 조건에 맞는 장소가 없어요.')),
        findsNothing);
    expect(other, findsNothing);
  });

  testWidgets(
      'recommendation groups fall back to Gangwon catalog without predictions',
      (tester) async {
    final spots = [
      const MapSpot(
        id: 'calm-shop',
        name: '강원 로컬 숍',
        category: 'POTATO_SHOP',
        latitude: 37.8,
        longitude: 128.2,
        address: '강원특별자치도 강릉시 테스트로 1',
        cityName: '강릉시',
        congestionLevel: 'UNKNOWN',
        stampEnabled: false,
        imageUrl: 'https://example.com/shop.jpg',
      ),
      const MapSpot(
        id: 'calm-tour',
        name: '강원 전시관',
        category: 'POTATO_TOUR',
        latitude: 37.5,
        longitude: 128.4,
        address: '강원특별자치도 평창군 테스트로 2',
        cityName: '평창군',
        congestionLevel: 'UNKNOWN',
        stampEnabled: false,
      ),
      const MapSpot(
        id: 'hot-market',
        name: '강원 전통시장',
        category: 'POTATO_MARKET',
        latitude: 38.2,
        longitude: 128.5,
        address: '강원특별자치도 속초시 테스트로 3',
        cityName: '속초시',
        congestionLevel: 'UNKNOWN',
        stampEnabled: false,
        imageUrl: 'https://example.com/market.jpg',
      ),
      const MapSpot(
        id: 'hot-cafe',
        name: '강원 감자 카페',
        category: 'POTATO_CAFE',
        latitude: 37.9,
        longitude: 127.7,
        address: '강원특별자치도 춘천시 테스트로 4',
        cityName: '춘천시',
        congestionLevel: 'UNKNOWN',
        stampEnabled: false,
      ),
      const MapSpot(
        id: 'outside-high',
        name: '인근 타지역 핫플',
        category: 'POTATO_MARKET',
        latitude: 37.6,
        longitude: 127.4,
        address: '경기도 가평군 테스트로 5',
        cityName: '가평군',
        congestionLevel: 'HIGH',
        stampEnabled: false,
      ),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => spots),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: const MaterialApp(home: MapScreen(hasMapConfiguration: true)),
    ));
    await tester.pumpAndSettle();

    final calm = find.byKey(const ValueKey('good-now-calm'));
    final hot = find.byKey(const ValueKey('good-now-hot'));
    await tester.scrollUntilVisible(calm, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.descendant(of: calm, matching: find.text('강원 로컬 숍')),
        findsOneWidget);
    expect(find.descendant(of: calm, matching: find.text('강원 전시관')),
        findsOneWidget);
    expect(find.descendant(of: calm, matching: find.text('테스트로 1')),
        findsOneWidget);
    expect(find.text('강원특별자치도 강릉시 테스트로 1'), findsNothing);
    expect(find.descendant(of: hot, matching: find.text('강원 전통시장')),
        findsOneWidget);
    expect(find.descendant(of: hot, matching: find.text('강원 감자 카페')),
        findsOneWidget);
    expect(find.text('인근 타지역 핫플'), findsNothing);
    expect(find.text('지금은 이 조건에 맞는 장소가 없어요.'), findsNothing);
    expect(find.byKey(const ValueKey('good-now-other')), findsNothing);
    expect(find.text('취향 따라 가볼 곳'), findsNothing);
    expect(find.text('강원도 장소 중 오늘 끌리는 곳을 골라보세요.'), findsNothing);
    expect(find.text('오늘 혼잡도 예측이 없는 장소는 장소 유형을 기준으로 골랐어요.'), findsNothing);
    expect(find.descendant(of: calm, matching: find.text('혼잡도 정보 없음')),
        findsNothing);
    expect(find.descendant(of: hot, matching: find.text('혼잡도 정보 없음')),
        findsNothing);
  });

  testWidgets('map tour resumes after course and recommended place visits',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesFeatureTourStatusStore.resetInProcessForTesting();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => _spots),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: MaterialApp(
          home: FeatureTourHost(
        tourId: 'map-navigation-test',
        steps: FeatureTourDefinitions.map,
        child: MapScreen(
          hasMapConfiguration: true,
          mapViewBuilder: (spots, onSpotSelected) => Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('test-native-marker'),
              onPressed: () => onSpotSelected(spots.first.id),
              child: const Text('장소 마커'),
            ),
          ),
        ),
      )),
    ));
    await _settleMapTour(tester);
    await tester.tap(find.text('다음'));
    await _settleMapTour(tester);
    expect(find.text('2 / 7'), findsOneWidget);
    await tester.tap(find.byKey(FeatureTourTargets.mapCourseCard));
    await _settleMapTour(tester);
    expect(find.byType(FeatureTourOverlay, skipOffstage: false), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    final detailContext = tester.element(find.text('강원도 감자 먹거리 코스'));
    Navigator.of(detailContext).pop();
    await _settleMapTour(tester);
    expect(find.text('3 / 7'), findsOneWidget);
    await tester.tap(find.byKey(FeatureTourTargets.mapGoodNowCard));
    await _settleMapTour(tester);
    expect(find.byType(FeatureTourOverlay), findsNothing);
    await tester.tap(find.byKey(const ValueKey('full-map-home-button')));
    await _settleMapTour(tester);
    expect(find.text('4 / 7'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-full-map-button')));
    await _settleMapTour(tester);
    expect(find.text('5 / 7'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('test-native-marker')));
    await _settleMapTour(tester);
    expect(find.text('6 / 7'), findsOneWidget);
    await tester.drag(
        find.byKey(FeatureTourTargets.spotSheetHandle), const Offset(0, -180));
    await _settleMapTour(tester);
    expect(find.text('7 / 7'), findsOneWidget);
    await tester.tap(find.byKey(FeatureTourTargets.routeMode));
    await _settleMapTour(tester);
    expect(find.byType(FeatureTourOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the discovery home before spot loading completes', (
    tester,
  ) async {
    final spots = Completer<List<MapSpot>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) => spots.future),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(hasMapConfiguration: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-spots-progress')), findsOneWidget);
    expect(find.text('강원도 여행 코스 짜기'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-full-map-button')), findsOneWidget);
    expect(find.byType(PotatoLoadingView), findsNothing);

    spots.complete(_spots);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-spots-progress')), findsNothing);
    expect(find.text('오늘 감자로 배 채워볼까? 🥔'), findsOneWidget);
  });

  for (final width in [360.0, 375.0, 390.0, 430.0]) {
    testWidgets('discovery home keeps section spacing at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spotDetailProvider.overrideWith(_testSpotDetail),
            mapSpotsProvider.overrideWith((ref) async => _spots),
            favoriteSpotControllerProvider.overrideWith(
              (ref) => _favoriteController(),
            ),
            favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
          ],
          child: const MaterialApp(
            home: MapScreen(hasMapConfiguration: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final preview = find.byKey(const ValueKey('map-discovery-preview-card'));
      final previewDecoration =
          tester.widget<Container>(preview).decoration! as BoxDecoration;
      expect(previewDecoration.border, isNull);
      expect(previewDecoration.boxShadow, isNotEmpty);
      final heroLastLine = find.text('추천 장소를 발견하고 내 동선에 담아보세요');
      final courseHeading = find.text('나만 몰랐던 강원도 이색 여행');
      expect(
          tester.getTopLeft(preview).dy - tester.getBottomLeft(heroLastLine).dy,
          greaterThanOrEqualTo(20));
      expect(
          tester.getTopLeft(courseHeading).dy -
              tester.getBottomLeft(preview).dy,
          greaterThanOrEqualTo(32));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders map discovery home and opens the full Kakao map', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
    expect(find.text('오늘은 어디로 떠나볼까요?'), findsOneWidget);
    expect(find.text('강원도 여행 코스 짜기'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-discovery-preview-card')),
        findsOneWidget);
    expect(find.text('내 동선 0곳'), findsNothing);
    expect(find.byKey(const ValueKey('discovery-route-button')), findsNothing);
    expect(find.byKey(const ValueKey('preview-route-button')), findsNothing);
    expect(find.text('나만 몰랐던 강원도 이색 여행'), findsOneWidget);
    expect(find.text('지도 크게 보기'), findsOneWidget);
    expect(renderedSpots, isEmpty);

    expect(find.text('오늘 감자로 배 채워볼까? 🥔'), findsOneWidget);
    await tester.ensureVisible(find.text('오늘 감자로 배 채워볼까? 🥔'));
    await tester.pumpAndSettle();
    final courseTitle = find.text('오늘 감자로 배 채워볼까? 🥔');
    await tester.ensureVisible(courseTitle);
    await tester.pumpAndSettle();
    await tester.tap(courseTitle);
    await tester.pumpAndSettle();

    expect(find.text('강원도 감자 먹거리 코스'), findsOneWidget);
    await _dragCourseDetailUntilVisible(tester, find.text('이 코스에 담긴 장소'));
    expect(find.text('이 코스에 담긴 장소'), findsOneWidget);

    Navigator.of(tester.element(find.text('이 코스에 담긴 장소'))).pop();
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('map-discovery-home')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(find.text('취향 따라 가볼 곳'), findsNothing);
    expect(find.text('강원도 장소 중 오늘 끌리는 곳을 골라보세요.'), findsNothing);
    expect(find.text('오늘 혼잡도 예측이 없는 장소는 장소 유형을 기준으로 골랐어요.'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('map-discovery-home')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(find.text('내향인 전용 여유로운 장소'), findsOneWidget);
    expect(find.text('외향인 전용 사람 좋아 핫플'), findsOneWidget);
    expect(find.text('혼잡도 예측 여유'), findsAtLeastNWidgets(1));
    expect(find.text('방문자 많음'), findsNothing);
    expect(find.text('강원 정선군'), findsAtLeastNWidgets(1));
    expect(find.text('화요일: 오전 11:00~오후 8:00'), findsAtLeastNWidgets(1));
    expect(find.text('감자빵 · 3,300원'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-full-map-button')),
      -260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-full-map-button')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id).toSet(), {'1', '2', '3', '4'});
    expect(find.text('전체'), findsOneWidget);
    expect(find.byKey(const ValueKey('full-map-home-button')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('full-map-locate-button')), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('길찾기'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-visit-verify-1')), findsOneWidget);
    expect(find.text('상세보기'), findsNothing);
    expect(find.byKey(FeatureTourTargets.mapMarker), findsOneWidget);
    final mapTourTargetSize =
        tester.getSize(find.byKey(FeatureTourTargets.mapMarker));
    expect(mapTourTargetSize.width, greaterThan(300));
    expect(mapTourTargetSize.height, greaterThan(250));

    await tester.tap(find.byKey(const ValueKey('full-map-home-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
  });

  testWidgets('keeps full map controls above the draggable spot sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeButton = find.byKey(const ValueKey('full-map-home-button'));
    final spotSheetHandle =
        find.byKey(const ValueKey('selected-spot-sheet-handle'));
    expect(homeButton, findsOneWidget);
    expect(spotSheetHandle, findsOneWidget);

    final initialTop = tester.getTopLeft(homeButton).dy;
    await tester.drag(spotSheetHandle, const Offset(0, -220));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(homeButton).dy, lessThan(initialTop));
  });

  testWidgets('full map labels yesterday prediction as reference only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final yesterday = DateTime.parse('${koreaDate()}T00:00:00Z')
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final spot = MapSpot.fromJson({
      'id': 1,
      'name': '어제 예측 장소',
      'category': 'POTATO_TOUR',
      'latitude': 37.38,
      'longitude': 128.66,
      'congestionReferenceLevel': 'LOW',
      'congestionReferenceDate': yesterday,
      'congestionReferenceSource': 'TOURISM_CONGESTION_API',
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_testSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => [spot]),
        favoriteSpotControllerProvider.overrideWith(
          (ref) => _favoriteController(),
        ),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: const MaterialApp(
        home: MapScreen(hasMapConfiguration: true, showFullMapInitially: true),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('어제('), findsOneWidget);
    expect(find.textContaining('실제 혼잡도나 오늘 예측이 아니에요'), findsOneWidget);
    expect(find.text('혼잡도 예측 여유'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a travel course to the route and opens route mode', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final courseTitle = find.text('오늘 감자로 배 채워볼까? 🥔');
    await tester.scrollUntilVisible(
      courseTitle,
      360,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('map-discovery-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(courseTitle);
    await tester.pumpAndSettle();
    await _dragCourseDetailUntilVisible(tester, find.text('내 동선에 2곳 담기'));
    await tester.tap(find.text('내 동선에 2곳 담기'));
    await tester.pumpAndSettle();

    expect(find.text('내 동선에 2곳을 담았어요'), findsOneWidget);
    expect(find.text('지도에서 여행 순서를 확인해보세요.'), findsOneWidget);

    await tester.tap(find.text('지도에서 확인하기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('favorite-route-sheet')), findsOneWidget);
    expect(find.text('내 동선 2곳'), findsOneWidget);
    expect(renderedSpots.length, 2);
  });

  testWidgets('shows road travel time on a course card and detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          travelCourseRouteEstimateProvider.overrideWith(
            (ref, route) async => const TravelCourseRouteEstimate(
              distanceMeters: 18400,
              durationSeconds: 2760,
              source: 'KAKAO_MOBILITY',
            ),
          ),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(home: MapScreen(hasMapConfiguration: true)),
      ),
    );
    await tester.pumpAndSettle();

    final courseTitle = find.text('오늘 감자로 배 채워볼까? 🥔');
    await tester.scrollUntilVisible(
      courseTitle,
      360,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('map-discovery-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2곳 · 차량 이동 46분'), findsWidgets);

    await tester.tap(courseTitle);
    await tester.pumpAndSettle();
    expect(find.text('차량 이동 46분'), findsWidgets);
    expect(find.textContaining('카카오모빌리티 추천 자동차 경로 기준'), findsOneWidget);
  });

  testWidgets('keeps an honest fallback when road travel time fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          travelCourseRouteEstimateProvider.overrideWith(
            (ref, route) => Future<TravelCourseRouteEstimate>.error(
              Exception('directions unavailable'),
            ),
          ),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(home: MapScreen(hasMapConfiguration: true)),
      ),
    );
    await tester.pumpAndSettle();

    final courseTitle = find.text('오늘 감자로 배 채워볼까? 🥔');
    await tester.scrollUntilVisible(
      courseTitle,
      360,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('map-discovery-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('차량 이동시간 미산정'), findsWidgets);

    await tester.tap(courseTitle);
    await tester.pumpAndSettle();
    expect(find.textContaining('차량 이동시간을 계산하지 못했어요'), findsOneWidget);
  });

  testWidgets('updates the place card when a different map marker is selected',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => Stack(
              children: [
                for (var index = 0; index < spots.length; index++)
                  Positioned(
                    left: 24 + (index * 64),
                    top: 180,
                    child: TextButton(
                      key: ValueKey('marker-${spots[index].id}'),
                      onPressed: () => onSpotSelected(
                          'Optional(potato-${spots[index].id}.0)'),
                      child: Text('마커 ${spots[index].id}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('대표 메뉴'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('marker-2')));
    await tester.pump();

    expect(find.text('감자 카페'), findsOneWidget);
    expect(find.text('정선 5일장'), findsNothing);
    expect(find.text('대표 메뉴'), findsOneWidget);
    expect(find.text('감자빵'), findsOneWidget);
    expect(find.text('3,300원'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('marker-3')));
    await tester.pump();

    expect(find.text('감자 체험장'), findsOneWidget);
    expect(find.text('감자 카페'), findsNothing);
    expect(find.text('대표 메뉴'), findsNothing);
  });

  testWidgets('shop never shows food menus even if the payload contains them',
      (tester) async {
    final shop = MapSpot.fromJson({
      'id': 97,
      'name': '유리알유희',
      'category': 'POTATO_SHOP',
      'latitude': 37.7945347,
      'longitude': 128.9182993,
      'address': '강원특별자치도 강릉시 창해로 351-2',
      'cityName': '강릉시',
      'menuItems': [
        {'name': '잘못 연결된 음식', 'priceWon': 1000}
      ],
    });
    await tester.pumpWidget(ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_failingSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => [shop]),
          favoriteSpotControllerProvider
              .overrideWith((ref) => _favoriteController()),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
            home: MapScreen(
          hasMapConfiguration: true,
          showFullMapInitially: true,
          mapViewBuilder: (_, __) => const SizedBox.expand(),
        ))));
    await tester.pumpAndSettle();
    expect(find.text('유리알유희'), findsOneWidget);
    expect(find.text('대표 메뉴'), findsNothing);
    expect(find.text('잘못 연결된 음식'), findsNothing);
    expect(find.text('메뉴와 가격은 방문 전 확인해주세요.'), findsNothing);
    expect(find.text('영업시간은 방문 전 확인해주세요.'), findsOneWidget);
  });

  testWidgets('shows address images tour info and detail menu in spot sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_richSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => Stack(
              children: [
                for (var index = 0; index < spots.length; index++)
                  Positioned(
                    left: 24 + (index * 64),
                    top: 180,
                    child: TextButton(
                      key: ValueKey('rich-marker-${spots[index].id}'),
                      onPressed: () => onSpotSelected(spots[index].id),
                      child: Text('마커 ${spots[index].id}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rich-marker-2')));
    await tester.pumpAndSettle();

    expect(find.text('강원특별자치도 정선군 감자길 12'), findsOneWidget);
    expect(find.text('이곳은 어떤 곳인가요?'), findsOneWidget);
    expect(find.textContaining('감자 디저트'), findsOneWidget);
    expect(find.text('이용 안내'), findsOneWidget);
    expect(find.text('영업 중'), findsOneWidget);
    expect(find.text('월요일: 오전 11:00~오후 8:00'), findsOneWidget);
    expect(find.text('평점 4.4'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('033-111-2222'), findsOneWidget);
    expect(find.text('11:00 - 20:00'), findsOneWidget);
    expect(find.text('대표 메뉴'), findsOneWidget);
    expect(find.text('감자라떼'), findsOneWidget);
    expect(find.text('5,500원'), findsOneWidget);
    expect(find.text('전화 문의'), findsOneWidget);
    expect(find.text('홈페이지'), findsOneWidget);
    expect(find.text('영업정보 출처: 한국관광공사'), findsOneWidget);
    expect(find.text('영업시간은 방문 전 확인해주세요.'), findsNothing);
  });

  testWidgets('decodes card photos at display density after marker changes',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        spotDetailProvider.overrideWith(_richSpotDetail),
        mapSpotsProvider.overrideWith((ref) async => _spots),
        favoriteSpotControllerProvider
            .overrideWith((ref) => _favoriteController()),
        favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
      ],
      child: MaterialApp(
        home: MapScreen(
          hasMapConfiguration: true,
          showFullMapInitially: true,
          mapViewBuilder: (spots, onSpotSelected) => Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => onSpotSelected('2'),
              child: const Text('사진 장소 선택'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사진 장소 선택'));
    await tester.pumpAndSettle();
    final gallery = find.byKey(const ValueKey('spot-image-gallery-2'));
    final photos = find.descendant(
      of: gallery,
      matching: find.byType(CachedNetworkImage),
    );
    expect(photos, findsWidgets);
    for (final element in photos.evaluate()) {
      final photo = element.widget as CachedNetworkImage;
      final logicalWidth = (element.renderObject as RenderBox).size.width;
      expect(photo.memCacheWidth, (logicalWidth * 3).ceil());
      expect(photo.memCacheHeight, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses spot list media and business info when detail fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_failingSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => Stack(
              children: [
                for (var index = 0; index < spots.length; index++)
                  Positioned(
                    left: 24 + (index * 64),
                    top: 180,
                    child: TextButton(
                      key: ValueKey('fallback-marker-${spots[index].id}'),
                      onPressed: () => onSpotSelected(spots[index].id),
                      child: Text('마커 ${spots[index].id}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('장소 이미지를 준비 중이에요'), findsOneWidget);
    expect(find.text('이용 안내'), findsOneWidget);
    expect(find.text('영업시간은 방문 전 확인해주세요.'), findsOneWidget);
    expect(find.text('메뉴와 가격은 방문 전 확인해주세요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fallback-marker-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('spot-image-gallery-2')), findsOneWidget);
    expect(find.text('화요일: 오전 11:00~오후 8:00'), findsWidgets);
    expect(find.text('대표 메뉴'), findsOneWidget);
    expect(find.text('감자빵'), findsOneWidget);
    expect(find.text('3,300원'), findsOneWidget);
  });

  testWidgets('updates map spots without recreating the map after filtering', (
    tester,
  ) async {
    var mountCount = 0;
    final renderedSpotIds = <List<String>>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => _MapMountProbe(
              spotIds: spots.map((spot) => spot.id).toList(),
              onMounted: () {
                mountCount += 1;
              },
              onRendered: (spotIds) {
                renderedSpotIds.add(spotIds);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(mountCount, 1);
    expect(renderedSpotIds.single, ['1', '2', '3', '4']);

    await tester.tap(find.text('카페·디저트'));
    await tester.pumpAndSettle();

    expect(find.text('감자 카페'), findsOneWidget);
    expect(mountCount, 1);
    expect(renderedSpotIds.last, ['2']);
  });

  testWidgets('shows expanded information for the currently selected marker', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/main/map',
      routes: [
        GoRoute(
          path: '/main/map',
          builder: (context, state) => MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) => Stack(
              children: [
                for (var index = 0; index < spots.length; index++)
                  Positioned(
                    left: 24 + (index * 64),
                    top: 180,
                    child: TextButton(
                      key: ValueKey('marker-${spots[index].id}'),
                      onPressed: () => onSpotSelected(spots[index].id),
                      child: Text('마커 ${spots[index].id}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/spots/:spotId',
          builder: (context, state) => Scaffold(
            body: Text('상세 ${state.pathParameters['spotId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('marker-2')));
    await tester.pump();
    await tester.ensureVisible(find.text('대표 메뉴'));
    await tester.pump();
    expect(find.text('감자 카페'), findsOneWidget);
    expect(find.text('대표 메뉴'), findsOneWidget);
    expect(find.text('상세보기'), findsNothing);
  });

  testWidgets('keeps all category spots visible when a spot is bookmarked', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'2'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id).toSet(), {'1', '2', '3', '4'});
    expect(find.text('내 동선 1곳'), findsOneWidget);
    expect(find.text('내 동선 1곳 저장됨'), findsNothing);
  });

  testWidgets('shows feedback and increases route count when bookmarking', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('내 동선에 추가'));
    await tester.pump();

    expect(find.text('내 동선에 추가했어요'), findsOneWidget);
    expect(find.text('내 동선 1곳'), findsOneWidget);
  });

  testWidgets('shows feedback and decreases route count when unbookmarking', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController({'1'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('동선에서 제거'));
    await tester.pump();

    expect(find.text('내 동선에서 삭제했어요'), findsOneWidget);
    expect(find.text('내 동선 0곳'), findsOneWidget);
  });

  testWidgets('route mode shows an empty state and returns to default map mode',
      (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots, isEmpty);
    expect(find.text('아직 내 동선이 비어 있어요 🥔'), findsOneWidget);
    expect(find.text('장소 둘러보기'), findsOneWidget);

    tester
        .widget<FilledButton>(find.byKey(const ValueKey('route-browse-button')))
        .onPressed!
        .call();
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id).toSet(), {'1', '2', '3', '4'});
    expect(find.text('정선 5일장'), findsOneWidget);
  });

  testWidgets('route mode renders only one saved spot without drag handle', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'2'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['2']);
    expect(find.byKey(const ValueKey('route-row-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-order-2')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-2')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('route-drag-2')), findsNothing);
  });

  testWidgets('route mode chip toggles back to the default spot sheet', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'1', '2'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['1', '2']);
    expect(find.byKey(const ValueKey('favorite-route-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id).toSet(), {'1', '2', '3', '4'});
    expect(find.byKey(const ValueKey('favorite-route-sheet')), findsNothing);
    expect(find.text('정선 5일장'), findsAtLeastNWidgets(1));
  });

  testWidgets('category filter exits route mode and shows category spots', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['1', '2', '3']);
    expect(find.byKey(const ValueKey('favorite-route-sheet')), findsOneWidget);

    await tester.tap(find.text('카페·디저트'));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['2']);
    expect(find.byKey(const ValueKey('favorite-route-sheet')), findsNothing);
    expect(find.text('감자 카페'), findsAtLeastNWidgets(1));
  });

  testWidgets('route mode reorders saved spots and refreshes numbering', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['1', '2', '3']);

    tester
        .widget<SliverReorderableList>(find.byType(SliverReorderableList))
        .onReorderItem!
        .call(2, 0);
    await tester.pumpAndSettle();

    expect(renderedSpots.map((spot) => spot.id), ['3', '1', '2']);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-3')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-1')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-2')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('route mode removes a saved spot and recalculates order numbers',
      (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _toggleableFavoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-remove-2')));
    await tester.pumpAndSettle();

    expect(find.text('내 동선에서 삭제했어요'), findsOneWidget);
    expect(find.text('내 동선 2곳'), findsOneWidget);
    expect(renderedSpots.map((spot) => spot.id), ['1', '3']);
    expect(find.byKey(const ValueKey('route-row-2')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-3')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('route mode fits compact mobile width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('내 동선'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-row-1')), findsOneWidget);
  });

  testWidgets('opens Kakao Map directions for the selected spot', (
    tester,
  ) async {
    Uri? launchedUri;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapUriLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('길찾기'));
    await tester.pump();
    await tester.tap(find.text('길찾기'));
    await tester.pump();

    expect(
      launchedUri.toString(),
      'https://map.kakao.com/link/to/'
      '%EC%A0%95%EC%84%A0%205%EC%9D%BC%EC%9E%A5,37.38,128.66',
    );
  });

  testWidgets('shows an error when Kakao Map cannot be opened', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            mapUriLauncher: (_) async => false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('길찾기'));
    await tester.pump();
    await tester.tap(find.text('길찾기'));
    await tester.pump();

    expect(
      find.text('카카오맵 길찾기를 열지 못했습니다. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('shows one actionable area when the spot API fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith(
            (ref) => Future<List<MapSpot>>.error(Exception('network error')),
          ),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('감자 스팟 정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('네트워크 연결을 확인한 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.textContaining('KAKAO_NATIVE_APP_KEY'), findsNothing);
  });

  for (final failure in _networkFailures) {
    testWidgets(
      'shows retry UI for ${failure.label} map loading failure',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              spotDetailProvider.overrideWith(_testSpotDetail),
              mapSpotsProvider.overrideWith(
                (ref) => Future<List<MapSpot>>.error(failure.error),
              ),
              favoriteSpotControllerProvider.overrideWith(
                (ref) => _favoriteController(),
              ),
              favoriteSpotRouteProvider
                  .overrideWith((ref) async => _emptyRoute),
            ],
            child: const MaterialApp(
              home: MapScreen(
                hasMapConfiguration: true,
                showFullMapInitially: true,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('감자 스팟 정보를 불러오지 못했습니다.'), findsOneWidget);
        expect(find.text('네트워크 연결을 확인한 뒤 다시 시도해주세요.'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  }

  testWidgets('distinguishes missing map configuration from an API failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: false,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지도를 표시할 수 없습니다.'), findsOneWidget);
    expect(
      find.text('지도 설정이 완료되지 않았습니다. 앱 관리자에게 문의해주세요.'),
      findsOneWidget,
    );
    expect(find.text('감자 스팟 정보를 불러오지 못했습니다.'), findsNothing);
  });

  testWidgets('uses backend route order only in route mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _route),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('추천 동선'), findsNothing);
    expect(find.text('이 동선 따라가기'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('route-mode-chip')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-3')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('route-order-2')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('highlights visit recommendations and selects their markers', (
    tester,
  ) async {
    var renderedSpots = <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          spotRecommendationsProvider(
            '1',
          ).overrideWith((ref) async => _recommendations),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            recommendationSourceSpotId: '1',
            mapViewBuilder: (spots, onSpotSelected) {
              renderedSpots = spots;
              return Stack(
                children: [
                  for (var index = 0; index < spots.length; index++)
                    Positioned(
                      left: 12 + (index * 52),
                      top: 190,
                      child: TextButton(
                        key: ValueKey(
                          'recommendation-marker-${spots[index].id}',
                        ),
                        onPressed: () => onSpotSelected(spots[index].id),
                        child: Text('마커 ${spots[index].id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('다음 추천 2곳 · 노란 핀'), findsOneWidget);
    expect(find.text('방문 후 추천 장소'), findsOneWidget);
    expect(find.text('감자 카페'), findsOneWidget);
    expect(
      renderedSpots
          .where((spot) => spot.isRecommended)
          .map((spot) => spot.id)
          .toSet(),
      {'2', '5'},
    );

    await tester.tap(find.byKey(const ValueKey('recommendation-marker-5')));
    await tester.pump();

    expect(find.text('감자 박물관'), findsOneWidget);
    expect(find.text('감자 카페'), findsNothing);
  });

  testWidgets('keeps the map usable when recommendations are empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          spotRecommendationsProvider(
            '1',
          ).overrideWith((ref) async => const <SpotRecommendation>[]),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            recommendationSourceSpotId: '1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('추천 장소를 찾지 못했어요'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('길찾기'), findsOneWidget);
    expect(find.text('상세보기'), findsNothing);
  });

  testWidgets('keeps the map usable when recommendations fail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spotDetailProvider.overrideWith(_testSpotDetail),
          mapSpotsProvider.overrideWith((ref) async => _spots),
          spotRecommendationsProvider('1').overrideWith(
            (ref) => Future<List<SpotRecommendation>>.error(
              Exception('recommendation error'),
            ),
          ),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            showFullMapInitially: true,
            recommendationSourceSpotId: '1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('추천 장소를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
  });
}

class _MapMountProbe extends StatefulWidget {
  const _MapMountProbe({
    required this.spotIds,
    required this.onMounted,
    required this.onRendered,
  });

  final List<String> spotIds;
  final VoidCallback onMounted;
  final ValueChanged<List<String>> onRendered;

  @override
  State<_MapMountProbe> createState() => _MapMountProbeState();
}

class _MapMountProbeState extends State<_MapMountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMounted();
    widget.onRendered(widget.spotIds);
  }

  @override
  void didUpdateWidget(covariant _MapMountProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.onRendered(widget.spotIds);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _NetworkFailureFixture {
  const _NetworkFailureFixture(this.label, this.error);

  final String label;
  final Object error;
}

final _networkFailures = [
  _NetworkFailureFixture(
    'timeout',
    DioException(
      requestOptions: RequestOptions(path: '/spots'),
      type: DioExceptionType.connectionTimeout,
    ),
  ),
  _NetworkFailureFixture(
    'connection error',
    DioException(
      requestOptions: RequestOptions(path: '/spots'),
      type: DioExceptionType.connectionError,
    ),
  ),
  const _NetworkFailureFixture(
    '500 response',
    ApiException(message: '서버 오류가 발생했습니다.', statusCode: 500),
  ),
];

Future<void> _settleMapTour(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> _dragCourseDetailUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final detailScrollView = find.byType(CustomScrollView).last;
  for (var attempt = 0; attempt < 8; attempt++) {
    if (target.evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(detailScrollView, const Offset(0, -520));
    await tester.pumpAndSettle();
  }
}

FavoriteSpotController _favoriteController([Set<String> spotIds = const {}]) {
  return FavoriteSpotController(
    MapSpotRepository(dio: Dio()),
    const LocalFavoriteSpotStorage(),
  )..state = AsyncValue.data(spotIds);
}

FavoriteSpotController _toggleableFavoriteController([
  Set<String> spotIds = const {},
]) {
  return FavoriteSpotController(
    _FakeMapSpotRepository(),
    _InMemoryLocalFavoriteSpotStorage(spotIds),
  )..state = AsyncValue.data(spotIds);
}

Future<SpotDetail> _testSpotDetail(Ref ref, String spotId) async {
  return SpotDetail(
    id: spotId,
    name: '평창무이예술관',
    category: 'POTATO_TOUR',
    cityName: '평창군',
    address: '강원특별자치도 평창군 봉평면',
    imageUrl: 'https://example.com/tour.jpg',
    description: '폐교를 예술 공간으로 꾸민 평창의 관광지입니다.',
    openingHours: '10:00 - 18:00',
    admissionFee: '성인 5,000원',
  );
}

Future<SpotDetail> _richSpotDetail(Ref ref, String spotId) async {
  return SpotDetail(
    id: spotId,
    name: '감자 카페',
    category: 'POTATO_CAFE',
    cityName: '정선군',
    address: '강원특별자치도 정선군 감자길 12',
    imageUrl: 'https://example.com/cafe.jpg',
    imageUrls: const [
      'https://example.com/cafe.jpg',
      'https://example.com/cafe-2.jpg',
      'https://example.com/cafe-3.jpg',
    ],
    description: '감자 디저트를 천천히 맛볼 수 있는 작은 카페입니다.',
    openingHours: '11:00 - 20:00',
    closedDays: '화요일',
    phone: '033-111-2222',
    website: 'https://example.com/cafe',
    rating: 4.4,
    businessOpeningHours: const SpotBusinessOpeningHours(
      openNow: true,
      todayText: '월요일: 오전 11:00~오후 8:00',
      weekdayDescriptions: [
        '월요일: 오전 11:00~오후 8:00',
        '화요일: 휴무',
      ],
    ),
    menuItems: const [
      MapSpotMenuItem(
        name: '감자라떼',
        priceWon: 5500,
        priceNote: null,
        verifiedOn: '2026-08-03',
      ),
    ],
  );
}

Future<SpotDetail> _failingSpotDetail(Ref ref, String spotId) async {
  throw const ApiException(message: '상세 정보를 불러오지 못했어요.');
}

class _FakeMapSpotRepository extends MapSpotRepository {
  _FakeMapSpotRepository() : super(dio: Dio());

  @override
  Future<List<FavoriteSpot>> fetchFavoriteSpots() async => const [];

  @override
  Future<FavoriteSpotToggleResult> addFavoriteSpot(String spotId) async {
    return FavoriteSpotToggleResult(spotId: spotId, favorite: true);
  }

  @override
  Future<FavoriteSpotToggleResult> removeFavoriteSpot(String spotId) async {
    return FavoriteSpotToggleResult(spotId: spotId, favorite: false);
  }

  @override
  Future<FavoriteSpotRoute> updateFavoriteSpotOrder(
    List<String> spotIds,
  ) async {
    return _emptyRoute;
  }

  @override
  Future<SpotDetail> fetchSpotDetail(String spotId) async {
    return SpotDetail(
      id: spotId,
      name: '평창무이예술관',
      category: 'POTATO_TOUR',
      cityName: '평창군',
      address: '강원특별자치도 평창군 봉평면',
      imageUrl: 'https://example.com/tour.jpg',
      description: '폐교를 예술 공간으로 꾸민 평창의 관광지입니다.',
      openingHours: '10:00 - 18:00',
      admissionFee: '성인 5,000원',
    );
  }
}

class _InMemoryLocalFavoriteSpotStorage extends LocalFavoriteSpotStorage {
  _InMemoryLocalFavoriteSpotStorage(Set<String> spotIds)
      : _spotIds = {...spotIds};

  Set<String> _spotIds;

  @override
  Future<Set<String>> readSpotIds() async => _spotIds;

  @override
  Future<void> saveSpotIds(Set<String> spotIds) async {
    _spotIds = {...spotIds};
  }
}

const _emptyRoute = FavoriteSpotRoute(
  routeName: '나만의 감자 동선',
  totalDistanceKm: 0,
  estimatedMinutes: 0,
  waypoints: [],
  polyline: [],
);

const _route = FavoriteSpotRoute(
  routeName: '나만의 감자 동선',
  totalDistanceKm: 12.3,
  estimatedMinutes: 30,
  waypoints: [
    FavoriteSpotRouteWaypoint(
      order: 1,
      spotId: '1',
      name: '정선 5일장',
      category: 'POTATO_MARKET',
      latitude: 37.38,
      longitude: 128.66,
      distanceFromPreviousKm: 0,
    ),
    FavoriteSpotRouteWaypoint(
      order: 2,
      spotId: '3',
      name: '감자 체험장',
      category: 'POTATO_EXPERIENCE',
      latitude: 37.40,
      longitude: 128.68,
      distanceFromPreviousKm: 6.1,
    ),
    FavoriteSpotRouteWaypoint(
      order: 3,
      spotId: '2',
      name: '감자 카페',
      category: 'POTATO_CAFE',
      latitude: 37.39,
      longitude: 128.67,
      distanceFromPreviousKm: 6.2,
    ),
  ],
  polyline: [
    FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
    FavoriteSpotRoutePoint(latitude: 37.40, longitude: 128.68),
    FavoriteSpotRoutePoint(latitude: 37.39, longitude: 128.67),
  ],
);

const _recommendations = [
  SpotRecommendation(
    spotId: '2',
    name: '감자 카페',
    category: 'POTATO_CAFE',
    latitude: 37.39,
    longitude: 128.67,
    address: '강원 정선군',
    cityName: '정선',
    imageUrl: null,
    externalRank: 1,
  ),
  SpotRecommendation(
    spotId: '5',
    name: '감자 박물관',
    category: 'POTATO_TOUR',
    latitude: 37.42,
    longitude: 128.70,
    address: '강원 정선군',
    cityName: '정선',
    imageUrl: null,
    externalRank: 2,
  ),
];

final _spots = [
  MapSpot(
    id: '1',
    name: '정선 5일장',
    category: 'POTATO_MARKET',
    latitude: 37.38,
    longitude: 128.66,
    address: '강원 정선군',
    cityName: '정선',
    congestionPredictionDate: koreaDate(),
    congestionSource: 'TOURISM_CONGESTION_API',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
  MapSpot(
    id: '2',
    name: '감자 카페',
    category: 'POTATO_CAFE',
    latitude: 37.39,
    longitude: 128.67,
    address: '강원 정선군',
    cityName: '정선',
    congestionPredictionDate: koreaDate(),
    congestionSource: 'TOURISM_CONGESTION_API',
    congestionLevel: 'LOW',
    stampEnabled: true,
    imageUrls: [
      'https://example.com/cafe-list.jpg',
      'https://example.com/cafe-list-2.jpg',
    ],
    phone: '033-000-0000',
    website: 'https://example.com/cafe',
    rating: 4.3,
    businessOpeningHours: const MapSpotBusinessOpeningHours(
      openNow: true,
      todayText: '화요일: 오전 11:00~오후 8:00',
      weekdayDescriptions: [
        '화요일: 오전 11:00~오후 8:00',
      ],
    ),
    menuItems: const [
      MapSpotMenuItem(
        name: '감자빵',
        priceWon: 3300,
        priceNote: null,
        verifiedOn: '2026-08-03',
      ),
      MapSpotMenuItem(
        name: '아메리카노',
        priceWon: 4800,
        priceNote: null,
        verifiedOn: '2026-08-03',
      ),
    ],
  ),
  MapSpot(
    id: '3',
    name: '감자 체험장',
    category: 'POTATO_EXPERIENCE',
    latitude: 37.40,
    longitude: 128.68,
    address: '강원 정선군',
    cityName: '정선',
    congestionPredictionDate: koreaDate(),
    congestionSource: 'TOURISM_CONGESTION_API',
    congestionLevel: 'HIGH',
    stampEnabled: true,
  ),
  MapSpot(
    id: '4',
    name: '감자 관광지',
    category: 'POTATO_TOUR',
    latitude: 37.41,
    longitude: 128.69,
    address: '강원 정선군',
    cityName: '정선',
    congestionPredictionDate: koreaDate(),
    congestionSource: 'TOURISM_CONGESTION_API',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
];
