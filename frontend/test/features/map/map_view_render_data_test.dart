import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
import 'package:potato_mubwanna/features/map/presentation/widget/map_view_render_data.dart';

void main() {
  test('keeps marker overlays when freshly allocated data is unchanged', () {
    expect(
      hasSameMapSpotRenderData(
        [_spot(id: '1'), _spot(id: '2')],
        const {'2'},
        [_spot(id: '1'), _spot(id: '2')],
        const {'2'},
      ),
      isTrue,
    );
    expect(
      hasSameRoutePolyline(
        const [
          FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
        ],
        const [
          FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
        ],
      ),
      isTrue,
    );
  });

  test('rebuilds marker overlays when visible marker data changes', () {
    expect(
      hasSameMapSpotRenderData(
        [_spot(id: '1')],
        const <String>{},
        [_spot(id: '2')],
        const <String>{},
      ),
      isFalse,
    );
    expect(
      hasSameMapSpotRenderData(
        [_spot(id: '1')],
        const <String>{},
        [_spot(id: '1')],
        const {'1'},
      ),
      isFalse,
    );
  });

  test('compares the current location by coordinates', () {
    expect(
      hasSameMapPoint(
        const FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
        const FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
      ),
      isTrue,
    );
    expect(
      hasSameMapPoint(
        const FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
        const FavoriteSpotRoutePoint(latitude: 37.39, longitude: 128.66),
      ),
      isFalse,
    );
  });
}

MapSpot _spot({required String id}) {
  return MapSpot(
    id: id,
    name: '감자 스팟 $id',
    category: 'POTATO_TOUR',
    latitude: 37.38,
    longitude: 128.66,
    address: '강원 정선군',
    cityName: '정선',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  );
}
