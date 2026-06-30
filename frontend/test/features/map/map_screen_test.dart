import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
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
}

FavoriteSpotController _favoriteController() {
  return FavoriteSpotController(
    MapSpotRepository(dio: Dio()),
    const LocalFavoriteSpotStorage(),
  )..state = const AsyncValue.data(<String>{});
}

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
