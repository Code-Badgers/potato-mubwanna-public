import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_map_projection.dart';
import 'package:potato_mubwanna/features/stamp/presentation/model/gangwon_map_region.dart';

void main() {
  test('places all 29 official attractions inside their declared city', () {
    final migration = _migrationFile().readAsStringSync();
    final attractions = _parseOfficialAttractions(migration);

    expect(attractions, hasLength(29));
    expect(
      attractions.map((attraction) => attraction.name).toSet(),
      containsAll(_expectedAttractionNames),
    );

    final coastBoundarySpots = <String>[];
    for (final attraction in attractions) {
      final region = gangwonMapRegions.singleWhere(
        (candidate) =>
            candidate.city == _normalizeCityName(attraction.cityName),
      );
      final position = projectToGangwonMap(
        latitude: attraction.latitude,
        longitude: attraction.longitude,
      );

      final isInside =
          region.polygons.any((polygon) => _containsPoint(polygon, position));
      final distanceToRegion = region.polygons
          .map((polygon) => _distanceToPolygon(polygon, position))
          .reduce((left, right) => left < right ? left : right);
      if (!isInside) {
        coastBoundarySpots.add(attraction.name);
      }

      expect(
        isInside || distanceToRegion <= 0.015,
        isTrue,
        reason: '${attraction.name} (${attraction.cityName}) is too far from '
            'its map region at $position (distance: $distanceToRegion)',
      );
    }

    // 장호항의 공식 좌표는 단순화된 삼척 해안선 바로 바깥에 있으므로
    // 같은 시군 경계와의 1.5% 이내 거리까지 해안 명소로 허용한다.
    expect(coastBoundarySpots, equals(const ['장호항']));
  });
}

File _migrationFile() {
  const relativePath =
      'backend/src/main/resources/db/migration/V24__seed_official_gangwon_attractions.sql';
  for (final path in [relativePath, '../$relativePath']) {
    final file = File(path);
    if (file.existsSync()) {
      return file;
    }
  }
  throw StateError('V24 official attraction migration was not found.');
}

List<_OfficialAttraction> _parseOfficialAttractions(String migration) {
  final attractions = <_OfficialAttraction>[
    for (final entry in const [
      (
        name: '남이섬',
        contentId: '128019',
        cityName: '춘천시',
      ),
      (
        name: '정선 5일장',
        contentId: '132003',
        cityName: '정선군',
      ),
    ])
      _parseUpdatedAttraction(migration, entry),
  ];
  final valuesPattern = RegExp(
    r"\('([^']+)',\s*\d+,\s*'([^']+)',\s*'[^']+',\s*([\d.]+),\s*([\d.]+),\s*'[^']*',\s*'([^']+)'",
  );
  attractions.addAll(
    valuesPattern.allMatches(migration).map(
          (match) => _OfficialAttraction(
            contentId: match.group(1)!,
            name: match.group(2)!,
            latitude: double.parse(match.group(3)!),
            longitude: double.parse(match.group(4)!),
            cityName: match.group(5)!,
          ),
        ),
  );
  return attractions;
}

_OfficialAttraction _parseUpdatedAttraction(
  String migration,
  ({String name, String contentId, String cityName}) expected,
) {
  final updatePattern = RegExp(
    "SET content_id = '${expected.contentId}',[\\s\\S]*?"
    r'latitude = ([\d.]+),[\s\S]*?longitude = ([\d.]+),[\s\S]*?'
    "city_name = '${expected.cityName}'",
  );
  final match = updatePattern.firstMatch(migration);
  if (match == null) {
    throw StateError('${expected.name} official coordinates were not found.');
  }
  return _OfficialAttraction(
    contentId: expected.contentId,
    name: expected.name,
    latitude: double.parse(match.group(1)!),
    longitude: double.parse(match.group(2)!),
    cityName: expected.cityName,
  );
}

bool _containsPoint(List<Offset> polygon, Offset point) {
  var inside = false;
  for (var current = 0, previous = polygon.length - 1;
      current < polygon.length;
      previous = current++) {
    final currentPoint = polygon[current];
    final previousPoint = polygon[previous];
    final intersects =
        (currentPoint.dy > point.dy) != (previousPoint.dy > point.dy) &&
            point.dx <
                (previousPoint.dx - currentPoint.dx) *
                        (point.dy - currentPoint.dy) /
                        (previousPoint.dy - currentPoint.dy) +
                    currentPoint.dx;
    if (intersects) {
      inside = !inside;
    }
  }
  return inside;
}

double _distanceToPolygon(List<Offset> polygon, Offset point) {
  var minimum = double.infinity;
  for (var index = 0; index < polygon.length; index++) {
    final distance = _distanceToSegment(
      point,
      polygon[index],
      polygon[(index + 1) % polygon.length],
    );
    if (distance < minimum) {
      minimum = distance;
    }
  }
  return minimum;
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final delta = end - start;
  if (delta.distanceSquared == 0) {
    return (point - start).distance;
  }
  final ratio =
      ((point - start).dx * delta.dx + (point - start).dy * delta.dy) /
          delta.distanceSquared;
  final nearest = start + delta * ratio.clamp(0.0, 1.0);
  return (point - nearest).distance;
}

String _normalizeCityName(String value) {
  return value.replaceAll(RegExp(r'(특별자치도|시|군|구)$'), '').trim();
}

class _OfficialAttraction {
  const _OfficialAttraction({
    required this.contentId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  final String contentId;
  final String name;
  final double latitude;
  final double longitude;
  final String cityName;
}

const _expectedAttractionNames = {
  '남이섬',
  '소양강 스카이워크',
  '뮤지엄 산',
  '안목해변',
  '경포대',
  '묵호등대',
  '논골담길',
  '황지연못',
  '속초관광수산시장',
  '영금정',
  '환선굴',
  '장호항',
  '수타사',
  '비발디파크',
  '횡성호수길',
  '청령포',
  '장릉',
  '대관령 양떼목장',
  '이효석문학관',
  '정선 5일장',
  '고석정',
  '산천어축제장',
  '박수근미술관',
  '두타연',
  '원대리 자작나무숲',
  '통일전망대',
  '화진포',
  '서피비치',
  '낙산사',
};
