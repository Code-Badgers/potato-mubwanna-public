import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';

void main() {
  test('fetches valid spot recommendations in external rank order', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _recommendationResponse,
              ),
            );
          },
        ),
      );

    final recommendations = await MapSpotRepository(
      dio: dio,
    ).fetchSpotRecommendations('1');

    expect(requestedPaths, ['/spots/1/recommendations']);
    expect(recommendations.map((item) => item.spotId), ['2', '3']);
    expect(recommendations.first.name, '원주소금산출렁다리');
    expect(recommendations.first.externalRank, 1);
    expect(recommendations.first.latitude, 37.3681);
    expect(recommendations.first.toMapSpot().isRecommended, isTrue);
    expect(recommendations.first.toMapSpot().imageUrl,
        'https://example.com/spot.jpg');
  });

  test('fetches TourAPI enriched spot detail fields', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _spotDetailResponse,
              ),
            );
          },
        ),
      );

    final detail = await MapSpotRepository(dio: dio).fetchSpotDetail('7');

    expect(requestedPaths, ['/spots/7']);
    expect(detail.imageUrl, 'https://tour.example.com/muei.jpg');
    expect(detail.description, contains('평창의 예술 공간'));
    expect(detail.openingHours, '10:00 - 18:00');
    expect(detail.admissionFee, '성인 5,000원');
    expect(detail.hasTourInfo, isTrue);
  });
}

const _recommendationResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': [
    {
      'spotId': 3,
      'name': '간현관광지',
      'category': 'POTATO_TOUR',
      'latitude': 37.364,
      'longitude': 127.834,
      'address': '강원특별자치도 원주시',
      'cityName': '원주시',
      'imageUrl': null,
      'externalRank': 2,
    },
    {
      'spotId': 99,
      'name': '좌표 없는 장소',
      'category': 'POTATO_TOUR',
      'latitude': 0,
      'longitude': 0,
      'address': '',
      'cityName': '',
      'imageUrl': null,
      'externalRank': 3,
    },
    {
      'spotId': 2,
      'name': '원주소금산출렁다리',
      'category': 'POTATO_TOUR',
      'latitude': 37.3681,
      'longitude': 127.833,
      'address': '강원특별자치도 원주시',
      'cityName': '원주시',
      'imageUrl': 'https://example.com/spot.jpg',
      'externalRank': 1,
    },
  ],
};

const _spotDetailResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'id': 7,
    'name': '평창무이예술관',
    'category': 'POTATO_TOUR',
    'cityName': '평창군',
    'imageUrl': 'https://tour.example.com/muei.jpg',
    'description': '평창의 예술 공간입니다.',
    'openingHours': '10:00 - 18:00',
    'closedDays': '월요일',
    'admissionFee': '성인 5,000원',
    'parking': '가능',
    'contactPhone': '033-000-0000',
  },
};
