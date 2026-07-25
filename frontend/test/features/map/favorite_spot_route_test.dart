import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';

void main() {
  test('parses favorite spot route response', () {
    final route = FavoriteSpotRoute.fromJson(const {
      'routeName': '나만의 감자 동선',
      'totalDistanceKm': 18.4,
      'estimatedMinutes': 45,
      'waypoints': [
        {
          'order': 1,
          'spotId': 10,
          'name': '정선 5일장',
          'category': 'POTATO_MARKET',
          'latitude': '37.3801000',
          'longitude': '128.6609000',
          'distanceFromPreviousKm': 0,
        },
        {
          'order': 2,
          'spotId': 20,
          'name': '감자 카페',
          'category': 'POTATO_CAFE',
          'latitude': 37.39,
          'longitude': 128.67,
          'distanceFromPreviousKm': 2.1,
        },
      ],
      'polyline': [
        {'latitude': '37.3801000', 'longitude': '128.6609000'},
        {'latitude': 37.39, 'longitude': 128.67},
      ],
    });

    expect(route.routeName, '나만의 감자 동선');
    expect(route.hasRoute, isTrue);
    expect(route.totalDistanceKm, 18.4);
    expect(route.estimatedMinutes, 45);
    expect(route.waypoints.map((waypoint) => waypoint.spotId), ['10', '20']);
    expect(route.waypoints.last.distanceFromPreviousKm, 2.1);
    expect(route.polyline.first.latitude, 37.3801);
  });

  test('uses empty route fallback for malformed response', () {
    final route = FavoriteSpotRoute.fromJson(const {});

    expect(route.routeName, '나만의 감자 동선');
    expect(route.hasRoute, isFalse);
    expect(route.totalDistanceKm, 0);
    expect(route.estimatedMinutes, 0);
    expect(route.waypoints, isEmpty);
    expect(route.polyline, isEmpty);
  });
}
