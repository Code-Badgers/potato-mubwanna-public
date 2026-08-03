import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_context_region.dart';

void main() {
  test('contains only the three provinces adjacent to Gangwon-do', () {
    expect(
      gangwonContextRegions.map((region) => region.name),
      orderedEquals(const ['경기도', '충청북도', '경상북도']),
    );
    expect(
      gangwonContextRegions.every((region) => region.polygon.length >= 3),
      isTrue,
    );
  });

  test('places each province on the expected side of Gangwon-do', () {
    final gyeonggi = gangwonContextRegions[0].polygon;
    final chungbuk = gangwonContextRegions[1].polygon;
    final gyeongbuk = gangwonContextRegions[2].polygon;

    expect(gyeonggi.map((point) => point.dx).reduce(_min), lessThan(0));
    expect(gyeonggi.map((point) => point.dx).reduce(_max), lessThan(0.4));
    expect(chungbuk.map((point) => point.dy).reduce(_min), greaterThan(0.8));
    expect(gyeongbuk.map((point) => point.dx).reduce(_min), greaterThan(0.25));
    expect(gyeongbuk.map((point) => point.dx).reduce(_max), greaterThan(1));
  });
}

double _min(double left, double right) => left < right ? left : right;

double _max(double left, double right) => left > right ? left : right;
