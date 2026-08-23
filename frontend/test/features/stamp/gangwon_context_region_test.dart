import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_context_region.dart';

void main() {
  test('contains northern and adjacent regions around Gangwon-do', () {
    expect(
      gangwonContextRegions.map((region) => region.name),
      orderedEquals(const ['북한', '경기도', '충청북도', '경상북도']),
    );
    expect(
      gangwonContextRegions.every(
        (region) => region.polygons.every((polygon) => polygon.length >= 3),
      ),
      isTrue,
    );
  });

  test('places each context region around the expected side of Gangwon-do', () {
    final northKorea = gangwonContextRegions[0].points;
    final gyeonggi = gangwonContextRegions[1].points;
    final chungbuk = gangwonContextRegions[2].points;
    final gyeongbuk = gangwonContextRegions[3].points;

    expect(northKorea.map((point) => point.dy).reduce(_min), lessThan(0));
    expect(northKorea.map((point) => point.dy).reduce(_max), lessThan(0.7));
    expect(gyeonggi.map((point) => point.dx).reduce(_min), lessThan(0));
    expect(gyeonggi.map((point) => point.dx).reduce(_max), lessThan(0.4));
    expect(chungbuk.map((point) => point.dy).reduce(_min), greaterThan(0.8));
    expect(gyeongbuk.map((point) => point.dx).reduce(_min), greaterThan(0.25));
    expect(gyeongbuk.map((point) => point.dx).reduce(_max), greaterThan(1));
  });
}

extension on GangwonContextRegion {
  Iterable<Offset> get points => polygons.expand((polygon) => polygon);
}

double _min(double left, double right) => left < right ? left : right;

double _max(double left, double right) => left > right ? left : right;
