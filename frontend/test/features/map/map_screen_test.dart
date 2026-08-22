import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
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
    expect(find.text('관광·쇼핑'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('전체')).dy,
      lessThan(tester.getTopLeft(find.text('내 동선 0곳')).dy),
    );
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

  testWidgets('recreates the map around the first spot after filtering', (
    tester,
  ) async {
    var mountCount = 0;
    final mountedSpotIds = <List<String>>[];

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
            mapViewBuilder: (spots, onSpotSelected) => _MapMountProbe(
              spotIds: spots.map((spot) => spot.id).toList(),
              onMounted: (spotIds) {
                mountCount += 1;
                mountedSpotIds.add(spotIds);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(mountCount, 1);
    expect(mountedSpotIds.single, ['1', '2', '3', '4']);

    await tester.tap(find.text('카페·디저트'));
    await tester.pumpAndSettle();

    expect(find.text('감자 카페'), findsOneWidget);
    expect(mountCount, 2);
    expect(mountedSpotIds.last, ['2']);
  });

  testWidgets('opens detail for the currently selected map marker', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/main/map',
      routes: [
        GoRoute(
          path: '/main/map',
          builder: (context, state) => MapScreen(
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
    await tester.ensureVisible(find.text('상세보기'));
    await tester.pump();
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();

    expect(find.text('상세 2'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('상세 2'), findsNothing);
    expect(find.text('감자 카페'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
  });

  testWidgets('keeps all category spots visible when a spot is bookmarked', (
    tester,
  ) async {
    var renderedSpots = const <MapSpot>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'2'}),
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

    expect(renderedSpots.map((spot) => spot.id).toSet(), {'1', '2', '3', '4'});
    expect(find.text('내 동선 1곳'), findsOneWidget);
  });

  testWidgets('opens Kakao Map directions for the selected spot', (
    tester,
  ) async {
    Uri? launchedUri;
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

  testWidgets('opens the complete recommended route in Kakao Map', (
    tester,
  ) async {
    Uri? launchedUri;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => _spots),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => _favoriteController({'1', '2', '3'}),
          ),
          favoriteSpotRouteProvider.overrideWith((ref) async => _route),
        ],
        child: MaterialApp(
          home: MapScreen(
            hasMapConfiguration: true,
            mapUriLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final routeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '이 동선 따라가기'),
    );
    routeButton.onPressed!();
    await tester.pump();

    expect(launchedUri?.pathSegments.take(3), ['link', 'by', 'car']);
    expect(
      launchedUri?.pathSegments
          .skip(3)
          .map((segment) => segment.split(',').first),
      ['정선 5일장', '감자 체험장', '감자 카페'],
    );
  });

  testWidgets('shows an error when Kakao Map cannot be opened', (
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

  for (final failure in _networkFailures) {
    testWidgets(
      'shows retry UI for ${failure.label} map loading failure',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mapSpotsProvider.overrideWith(
                (ref) => Future<List<MapSpot>>.error(failure.error),
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

class _MapMountProbe extends StatefulWidget {
  const _MapMountProbe({required this.spotIds, required this.onMounted});

  final List<String> spotIds;
  final ValueChanged<List<String>> onMounted;

  @override
  State<_MapMountProbe> createState() => _MapMountProbeState();
}

class _MapMountProbeState extends State<_MapMountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMounted(widget.spotIds);
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
    menuItems: [
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
