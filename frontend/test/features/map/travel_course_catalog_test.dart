import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/data/travel_course_catalog.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';

MapSpot spot(String id, String name, String category,
    {String city = '강릉', String address = '', String? image}) => MapSpot(
  id: id, name: name, category: category, latitude: 37.77, longitude: 128.95,
  address: address, cityName: city, imageUrl: image,
  congestionLevel: 'LOW', stampEnabled: true,
);

void main() {
  final food = [
    spot('1', '감자옹심이', 'POTATO_RESTAURANT', image: 'https://example.com/food.jpg'),
    spot('2', '중앙시장', 'POTATO_MARKET'),
    spot('3', '감자빵 카페', 'POTATO_CAFE'),
  ];
  TravelCourse foodCourse(List<MapSpot> spots) =>
      buildTravelCourses(spots).firstWhere((course) => course.id == 'potato_food');

  test('matched places form a local course with honest duration and image', () {
    final course = foodCourse(food);
    expect(course.spots.map((spot) => spot.id), ['1', '2', '3']);
    expect(course.heroImageUrl, 'https://example.com/food.jpg');
    expect(course.estimatedDuration, '소요시간 미산정');
    expect(course.description, contains('강릉'));
    expect(course.editorialIntro, '감자옹심이 → 중앙시장 → 감자빵 카페');
  });
  test('missing stop is omitted instead of using unrelated venue and copy', () {
    final course = foodCourse([
      food[0], food[1], spot('wrong', '공원', 'POTATO_TOUR'),
    ]);
    expect(course.spots.map((spot) => spot.id), ['1', '2']);
    expect(course.description, contains('2곳'));
    expect(course.editorialIntro, isNot(contains('디저트')));
    expect(course.stops.every((stop) => stop.transitionText.isEmpty), isTrue);
  });
  test('does not join different cities or expose single-stop courses', () {
    final courses = buildTravelCourses([
      food[0], spot('2', '중앙시장', 'POTATO_MARKET', city: '속초'),
    ]);
    expect(courses, isEmpty);
    expect(buildTravelCourses([]), isEmpty);
  });
  test('chooses the city with more matching stops and normalizes city suffix', () {
    final course = foodCourse([
      spot('other', '감자옹심이', 'POTATO_RESTAURANT', city: '속초'),
      food[0], food[1], spot('3', '감자빵 카페', 'POTATO_CAFE', city: '강릉시'),
    ]);
    expect(course.spots.map((spot) => spot.id), ['1', '2', '3']);
  });
  test('never borrows a hero image from a place outside the course', () {
    final course = foodCourse([
      food[1], food[2], spot('elsewhere', '감자옹심이', 'POTATO_RESTAURANT',
        city: '속초', image: 'https://example.com/elsewhere.jpg'),
    ]);
    expect(course.heroImageUrl, isNull);
  });
  test('address keywords and wrong categories cannot fill a themed stop', () {
    expect(buildTravelCourses([
      spot('1', '식당', 'POTATO_RESTAURANT', address: '감자옹심이길'),
      food[1], spot('3', '감자빵 박물관', 'POTATO_TOUR'),
    ]).where((course) => course.id == 'potato_food'), isEmpty);
  });
  test('unknown city does not form a course', () {
    expect(buildTravelCourses([
      spot('1', '감자옹심이', 'POTATO_RESTAURANT', city: ''),
      spot('2', '중앙시장', 'POTATO_MARKET', city: ''),
    ]), isEmpty);
  });
  test('reuses unchanged data and recomputes when a city changes', () {
    expect(identical(buildTravelCourses(food), buildTravelCourses(food)), isTrue);
    final changed = foodCourse([
      food[0], food[1], spot('3', '감자빵 카페', 'POTATO_CAFE', city: '속초'),
    ]);
    expect(changed.stops, hasLength(2));
  });
}
