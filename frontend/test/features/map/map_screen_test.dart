import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
import 'package:potato_mubwanna/features/map/domain/spot_recommendation.dart';
import 'package:potato_mubwanna/features/map/presentation/screen/map_screen.dart';

void main() {
  testWidgets('renders map home discovery UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    expect(find.text('감자 찾기'), findsNothing);
    expect(find.text('강원'), findsNothing);
    expect(find.text('내 동선 0곳'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('관광'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
  });

  testWidgets('updates the place card when a different map marker is selected',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('marker-2')));
    await tester.pump();

    expect(find.text('감자 카페'), findsOneWidget);
    expect(find.text('정선 5일장'), findsNothing);
  });

  testWidgets('shows one actionable area when the spot API fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith(
            (ref) => Future<List<MapSpot>>.error(Exception('network error')),
          ),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('감자 스팟 정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('네트워크 연결을 확인한 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.textContaining('KAKAO_NATIVE_APP_KEY'), findsNothing);
  });

  testWidgets('distinguishes missing map configuration from an API failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController(),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _emptyRoute),
        ],
        child: const MaterialApp(
          home: MapScreen(hasMapConfiguration: false),
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

  testWidgets('uses backend recommended route when available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _route),
        ],
        child: const MaterialApp(
          home: MapScreen(hasMapConfiguration: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('추천 동선'), findsOneWidget);
    expect(find.text('3곳 · 직선 12.3km'), findsOneWidget);
    expect(find.text('정선 5일장'), findsWidgets);
    expect(find.text('감자 체험장'), findsOneWidget);
    expect(find.text('감자 카페'), findsOneWidget);
  });

  testWidgets('highlights visit recommendations and selects their markers', (
    tester,
  ) async {
    var renderedSpots = <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    expect(find.text('다음 추천 2곳 · 보라색 핀'), findsOneWidget);
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
            recommendationSourceSpotId: '1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('추천 장소를 찾지 못했어요'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
  });

  testWidgets('keeps the map usable when recommendations fail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

FavoriteSpotController _favoriteController([Set<String> spotIds = const {}]) {
  return FavoriteSpotController(
    MapSpotRepository(dio: Dio()),
    const LocalFavoriteSpotStorage(),
  )..state = AsyncValue.data(spotIds);
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

const _spots = [
  MapSpot(
    id: '1',
    name: '정선 5일장',
    category: 'POTATO_MARKET',
    latitude: 37.38,
    longitude: 128.66,
    address: '강원 정선군',
    cityName: '정선',
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
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '3',
    name: '감자 체험장',
    category: 'POTATO_EXPERIENCE',
    latitude: 37.40,
    longitude: 128.68,
    address: '강원 정선군',
    cityName: '정선',
    congestionLevel: 'NORMAL',
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
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
];
