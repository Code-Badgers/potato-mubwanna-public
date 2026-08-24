import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/data/travel_course_catalog.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';

void main() {
  test('builds six editorial travel courses from map spots', () {
    final courses = buildTravelCourses(_spots);

    expect(courses, hasLength(6));
    expect(
      courses.map((course) => course.title),
      containsAll([
        '오늘 감자로 배 채워볼까? 🥔',
        '사람 구경도 여행이지! 👋',
        '강원도에서 요즘 제일 핫한 곳 🔥',
        '사람 많은 곳은 조금 힘들어요 🌿',
        '오늘은 바다만 보고 싶어 🌊',
        '그냥 찍어도 분위기 좋은 곳 📷',
      ]),
    );
    for (final course in courses) {
      expect(course.categoryTitle, isNotEmpty);
      expect(course.editorialIntro, isNotEmpty);
      expect(
          course.heroImageAsset, startsWith('assets/stamps/passport/spots/'));
      expect(course.tags.length, greaterThanOrEqualTo(3));
      expect(course.stops, hasLength(3));
      expect(course.spots.map((spot) => spot.id).toSet(), hasLength(3));
    }
    expect(courses.first.heroImageUrl, 'https://example.com/ongshimi.jpg');
  });

  test('reuses resolved courses for unchanged spot data', () {
    final first = buildTravelCourses(_spots);
    final second = buildTravelCourses(_spots);

    expect(identical(first, second), isTrue);
  });
}

const _spots = [
  MapSpot(
    id: '1',
    name: '토지옹심이 원주',
    category: 'POTATO_RESTAURANT',
    latitude: 37.34,
    longitude: 127.92,
    address: '강원 원주시',
    cityName: '원주',
    imageUrl: 'https://example.com/ongshimi.jpg',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '2',
    name: '속초관광수산시장',
    category: 'POTATO_MARKET',
    latitude: 38.20,
    longitude: 128.58,
    address: '강원 속초시',
    cityName: '속초',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
  MapSpot(
    id: '3',
    name: '안목해변 카페거리',
    category: 'POTATO_CAFE',
    latitude: 37.77,
    longitude: 128.95,
    address: '강원 강릉시',
    cityName: '강릉',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '4',
    name: '뮤지엄 산',
    category: 'POTATO_TOUR',
    latitude: 37.41,
    longitude: 127.83,
    address: '강원 원주시',
    cityName: '원주',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '5',
    name: '서피비치',
    category: 'POTATO_TOUR',
    latitude: 38.03,
    longitude: 128.73,
    address: '강원 양양군',
    cityName: '양양',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
  MapSpot(
    id: '6',
    name: '원대리 자작나무숲',
    category: 'POTATO_TOUR',
    latitude: 37.99,
    longitude: 128.20,
    address: '강원 인제군',
    cityName: '인제',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '7',
    name: '청령포',
    category: 'POTATO_TOUR',
    latitude: 37.18,
    longitude: 128.45,
    address: '강원 영월군',
    cityName: '영월',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '8',
    name: '영금정',
    category: 'POTATO_TOUR',
    latitude: 38.21,
    longitude: 128.60,
    address: '강원 속초시',
    cityName: '속초',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
  MapSpot(
    id: '9',
    name: '낙산사',
    category: 'POTATO_TOUR',
    latitude: 38.12,
    longitude: 128.63,
    address: '강원 양양군',
    cityName: '양양',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
];
