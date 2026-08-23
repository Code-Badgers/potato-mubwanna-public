import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_context_region.dart';

void main() {
  test('contains continuous Korean peninsula landmass around Gangwon-do', () {
    expect(
      gangwonContextRegions.map((region) => region.name),
      orderedEquals(const ['한반도 북부', '한반도 남부']),
    );
    expect(
      gangwonContextRegions.every(
        (region) => region.polygons.every((polygon) => polygon.length >= 3),
      ),
      isTrue,
    );
  });

  test('keeps northern, western, and southern landmass context visible', () {
    final northernLandmass = gangwonContextRegions[0].points;
    final southernLandmass = gangwonContextRegions[1].points;

    expect(northernLandmass.map((point) => point.dy).reduce(_min), lessThan(0));
    expect(
      northernLandmass.map((point) => point.dx).reduce(_min),
      lessThan(0),
    );
    expect(
      northernLandmass.map((point) => point.dx).reduce(_max),
      greaterThan(1),
    );
    expect(
      southernLandmass.map((point) => point.dx).reduce(_min),
      lessThan(0),
    );
    expect(
      southernLandmass.map((point) => point.dx).reduce(_max),
      greaterThan(1),
    );
    expect(
      southernLandmass.map((point) => point.dy).reduce(_max),
      greaterThan(1),
    );
  });
}

extension on GangwonContextRegion {
  Iterable<Offset> get points => polygons.expand((polygon) => polygon);
}

double _min(double left, double right) => left < right ? left : right;

double _max(double left, double right) => left > right ? left : right;
