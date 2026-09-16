import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/shared/models/congestion_prediction.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
import 'package:potato_mubwanna/features/spot/domain/spot_detail.dart';

void main() {
  test('uses Korean date across midnight rather than UTC or device date', () {
    final now = DateTime.parse('2026-09-12T15:30:00Z');
    expect(koreaDate(now), '2026-09-13');
    expect(currentCongestionLevel('LOW', '2026-09-13', now: now), 'LOW');
    expect(currentCongestionLevel('LOW', '2026-09-12', now: now), 'UNKNOWN');
  });
  test('missing, old, future, invalid date and unknown level are not normal', () {
    final now = DateTime.parse('2026-09-13T01:00:00Z');
    for (final date in [null, '2026-09-12', '2026-09-14', 'invalid']) {
      expect(currentCongestionLevel('NORMAL', date, now: now), 'UNKNOWN');
    }
    expect(currentCongestionLevel('BOGUS', '2026-09-13', now: now), 'UNKNOWN');
    expect(congestionLabel('UNKNOWN'), '정보 없음');
  });
  test('list, recommended copy and detail preserve today metadata', () {
    final json = <String, dynamic>{'id': 1, 'congestionLevel': 'LOW',
      'congestionPredictionDate': koreaDate(), 'congestionSource': 'TOURISM_CONGESTION_API'};
    final map = MapSpot.fromJson(json);
    final detail = SpotDetail.fromJson(json);
    expect(map.congestionLabel, '여유');
    expect(map.asRecommended().congestionDescription, map.congestionDescription);
    expect(detail.congestionDescription, contains(koreaDate()));
    expect(detail.congestionDescription, contains('한국관광공사'));
    expect(detail.congestionDescription, contains('실시간 현장 혼잡도가 아닌'));
  });
  test('old server payload is treated as unavailable on both screens', () {
    final json = <String, dynamic>{'id': 1, 'congestionLevel': 'NORMAL'};
    expect(MapSpot.fromJson(json).congestionLevel, 'UNKNOWN');
    expect(SpotDetail.fromJson(json).congestionLabel, '정보 없음');
  });

  test('past prediction is labeled as reference, never as current congestion', () {
    final now = DateTime.parse('2026-09-15T15:30:00Z');
    expect(historicalCongestionDescription(
      'LOW', '2026-09-15', 'TOURISM_CONGESTION_API', now: now,
    ), contains('어제(9월 15일) 예측: 여유 · 참고용'));
    expect(historicalCongestionDescription(
      'HIGH', '2026-09-09', 'TOURISM_CONGESTION_API', now: now,
    ), contains('지난주 같은 요일(9월 9일) 예측: 혼잡 · 참고용'));
    expect(historicalCongestionDescription(
      'NORMAL', '2026-09-14', 'TOURISM_CONGESTION_API', now: now,
    ), isNull);
    expect(historicalCongestionDescription(
      'LOW', '2026-09-16', 'TOURISM_CONGESTION_API', now: now,
    ), isNull);
    expect(historicalCongestionDescription(
      'BOGUS', '2026-09-15', 'TOURISM_CONGESTION_API', now: now,
    ), isNull);

    final yesterday = DateTime.parse('${koreaDate()}T00:00:00Z')
        .subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final json = <String, dynamic>{
      'id': 1,
      'congestionLevel': null,
      'congestionReferenceLevel': 'LOW',
      'congestionReferenceDate': yesterday,
      'congestionReferenceSource': 'TOURISM_CONGESTION_API',
    };
    final map = MapSpot.fromJson(json);
    final detail = SpotDetail.fromJson(json);
    expect(map.congestionLevel, 'UNKNOWN');
    expect(map.asRecommended().congestionReferenceDescription, contains('참고용'));
    expect(detail.congestionReferenceDescription, contains('실제 혼잡도나 오늘 예측이 아니에요'));
  });
}
