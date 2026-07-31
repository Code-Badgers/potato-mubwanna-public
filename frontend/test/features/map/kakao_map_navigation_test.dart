import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/application/kakao_map_navigation.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';

void main() {
  test('builds a destination URL with an encoded spot name', () {
    final uri = KakaoMapNavigation.destinationUri(
      const _TestMapSpot(name: '감자 카페/본점,입구'),
    );

    expect(
      uri.toString(),
      'https://map.kakao.com/link/to/'
      '%EA%B0%90%EC%9E%90%20%EC%B9%B4%ED%8E%98%2F%EB%B3%B8%EC%A0%90%2C%EC%9E%85%EA%B5%AC,'
      '37.38,128.66',
    );
  });

  test('builds a car route URL in the recommended order', () {
    final uri = KakaoMapNavigation.routeUri(const [
      _TestMapSpot(name: '첫 장소', latitude: 37.38, longitude: 128.66),
      _TestMapSpot(name: '둘째 장소', latitude: 37.39, longitude: 128.67),
      _TestMapSpot(name: '마지막 장소', latitude: 37.40, longitude: 128.68),
    ]);

    expect(
        uri.pathSegments.take(4), ['link', 'by', 'car', '첫 장소,37.38,128.66']);
    expect(uri.pathSegments[4], '둘째 장소,37.39,128.67');
    expect(uri.pathSegments[5], '마지막 장소,37.4,128.68');
  });

  test('limits a route to Kakao Map departure, waypoints, and destination', () {
    final spots = List.generate(
      8,
      (index) => _TestMapSpot(
        name: '장소 $index',
        latitude: 37 + (index / 100),
        longitude: 128 + (index / 100),
      ),
    );

    final uri = KakaoMapNavigation.routeUri(spots);

    expect(uri.pathSegments.skip(3), hasLength(7));
    expect(uri.toString(), contains(Uri.encodeComponent('장소 6')));
    expect(uri.toString(), isNot(contains(Uri.encodeComponent('장소 7'))));
  });

  test('rejects a route with fewer than two spots', () {
    expect(
      () => KakaoMapNavigation.routeUri(const [_TestMapSpot()]),
      throwsArgumentError,
    );
  });
}

class _TestMapSpot extends MapSpot {
  const _TestMapSpot({
    super.name = '정선 5일장',
    super.latitude = 37.38,
    super.longitude = 128.66,
  }) : super(
          id: '1',
          category: 'POTATO_MARKET',
          address: '강원 정선군',
          cityName: '정선',
          congestionLevel: 'NORMAL',
          stampEnabled: true,
        );
}
