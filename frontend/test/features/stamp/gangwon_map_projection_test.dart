import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_map_projection.dart';

void main() {
  test('matches EPSG:5179 reference coordinates for official attractions', () {
    final namiIsland = projectToKorea2000(
      latitude: 37.7962651,
      longitude: 127.5254892,
    );
    final jeongseonMarket = projectToKorea2000(
      latitude: 37.3805311,
      longitude: 128.6647911,
    );
    final unificationObservatory = projectToKorea2000(
      latitude: 38.5147706,
      longitude: 128.4173975,
    );

    expect(namiIsland.dx, closeTo(1002244.0607, 0.01));
    expect(namiIsland.dy, closeTo(1977395.8877, 0.01));
    expect(jeongseonMarket.dx, closeTo(1103121.6636, 0.01));
    expect(jeongseonMarket.dy, closeTo(1931908.6808, 0.01));
    expect(unificationObservatory.dx, closeTo(1079979.5473, 0.01));
    expect(unificationObservatory.dy, closeTo(2057516.1225, 0.01));
  });

  test('normalizes official attractions into the Gangwon map bounds', () {
    final positions = [
      projectToGangwonMap(latitude: 37.7962651, longitude: 127.5254892),
      projectToGangwonMap(latitude: 37.3805311, longitude: 128.6647911),
      projectToGangwonMap(latitude: 38.5147706, longitude: 128.4173975),
    ];

    for (final position in positions) {
      expect(position.dx, inInclusiveRange(0, 1));
      expect(position.dy, inInclusiveRange(0, 1));
    }
  });
}
