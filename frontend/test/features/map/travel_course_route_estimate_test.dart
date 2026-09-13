import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/domain/travel_course_route_estimate.dart';

void main() {
  test('formats rounded-up vehicle travel duration', () {
    expect(
      const TravelCourseRouteEstimate(
        distanceMeters: 18400,
        durationSeconds: 2760,
        source: 'KAKAO_MOBILITY',
      ).durationLabel,
      '차량 이동 46분',
    );
    expect(
      const TravelCourseRouteEstimate(
        distanceMeters: 70000,
        durationSeconds: 3661,
        source: 'KAKAO_MOBILITY',
      ).durationLabel,
      '차량 이동 1시간 2분',
    );
  });

  test('uses ordered spot ids as the provider key', () {
    expect(TravelCourseRouteKey(['1', '2']), TravelCourseRouteKey(['1', '2']));
    expect(
      TravelCourseRouteKey(['1', '2']),
      isNot(TravelCourseRouteKey(['2', '1'])),
    );
  });

  test('rejects an incomplete route response', () {
    expect(
      () => TravelCourseRouteEstimate.fromJson(const {
        'distanceMeters': 18400,
        'source': 'KAKAO_MOBILITY',
      }),
      throwsFormatException,
    );
  });
}
