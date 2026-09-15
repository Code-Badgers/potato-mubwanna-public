import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';

void main() {
  test('keeps only Gangwon spots in the map catalog', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'success': true,
                  'data': [
                    {
                      'id': 1,
                      'name': '강원 관광지',
                      'category': 'POTATO_TOUR',
                      'latitude': 37.8,
                      'longitude': 128.2,
                      'address': '강원특별자치도 강릉시 테스트로 1',
                      'cityName': '강릉시',
                    },
                    {
                      'id': 2,
                      'name': '인근 타지역 관광지',
                      'category': 'POTATO_TOUR',
                      'latitude': 37.6,
                      'longitude': 127.4,
                      'address': '경기도 가평군 테스트로 2',
                      'cityName': '가평군',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

    final spots = await MapSpotRepository(dio: dio).fetchSpots();

    expect(spots.map((spot) => spot.name), ['강원 관광지']);
    expect(spots.single.isGangwonProvince, isTrue);
  });

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
    expect(detail.address, '강원특별자치도 평창군 봉평면');
    expect(detail.imageUrl, 'https://tour.example.com/muei.jpg');
    expect(detail.imageUrls, [
      'https://tour.example.com/muei.jpg',
      'https://tour.example.com/muei-2.jpg',
    ]);
    expect(detail.menuItems.first.name, '감자전');
    expect(detail.description, contains('평창의 예술 공간'));
    expect(detail.openingHours, '10:00 - 18:00');
    expect(detail.admissionFee, '성인 5,000원');
    expect(detail.phone, '033-111-2222');
    expect(detail.website, 'https://example.com/muei');
    expect(detail.rating, 4.3);
    expect(detail.businessOpeningHours?.openNow, isTrue);
    expect(detail.businessOpeningHours?.todayText, '월요일: 오전 10:00~오후 8:00');
    expect(detail.hasTourInfo, isTrue);
    expect(detail.hasBusinessInfo, isTrue);
  });

  test('requests a road route estimate in course order', () async {
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'success': true,
                  'data': {
                    'distanceMeters': 18400,
                    'durationSeconds': 2760,
                    'source': 'KAKAO_MOBILITY',
                  },
                },
              ),
            );
          },
        ),
      );

    final estimate = await MapSpotRepository(
      dio: dio,
    ).fetchTravelCourseRouteEstimate(['3', '1', '2']);

    expect(request?.path, '/spots/route-estimate');
    expect(request?.method, 'POST');
    expect(request?.data, {'spotIds': [3, 1, 2]});
    expect(estimate.distanceMeters, 18400);
    expect(estimate.durationSeconds, 2760);
    expect(estimate.durationLabel, '차량 이동 46분');
  });
}

const _recommendationResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': [
    {
      'spotId': 4,
      'name': '인근 타지역 관광지',
      'category': 'POTATO_TOUR',
      'latitude': 37.6,
      'longitude': 127.4,
      'address': '경기도 가평군',
      'cityName': '가평군',
      'imageUrl': 'https://example.com/outside.jpg',
      'externalRank': 0,
    },
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
    'address': '강원특별자치도 평창군 봉평면',
    'cityName': '평창군',
    'imageUrl': 'https://tour.example.com/muei.jpg',
    'imageUrls': [
      'https://tour.example.com/muei.jpg',
      'https://tour.example.com/muei-2.jpg',
    ],
    'menuItems': [
      {
        'name': '감자전',
        'priceWon': 9000,
        'priceNote': null,
        'verifiedOn': '2026-08-03',
      },
    ],
    'description': '평창의 예술 공간입니다.',
    'openingHours': '10:00 - 18:00',
    'closedDays': '월요일',
    'admissionFee': '성인 5,000원',
    'parking': '가능',
    'contactPhone': '033-000-0000',
    'googlePlaceId': 'places/muei',
    'phone': '033-111-2222',
    'website': 'https://example.com/muei',
    'rating': 4.3,
    'businessOpeningHours': {
      'openNow': true,
      'todayText': '월요일: 오전 10:00~오후 8:00',
      'weekdayDescriptions': [
        '월요일: 오전 10:00~오후 8:00',
        '화요일: 오전 10:00~오후 8:00',
      ],
    },
  },
};
