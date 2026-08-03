import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/travel_record/data/travel_record_repository.dart';

void main() {
  test('fetches and maps travel records', () async {
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
                data: _travelRecordResponse,
              ),
            );
          },
        ),
      );

    final records = await TravelRecordRepository(
      dio: dio,
    ).fetchTravelRecords();

    expect(requestedPaths, ['/users/me/visits']);
    expect(records, hasLength(2));
    expect(records.first.visitId, 2);
    expect(records.first.spotId, 20);
    expect(records.first.spotName, '감자 카페');
    expect(records.first.categoryLabel, '카페');
    expect(
      records.first.uploadedImageUrl,
      '/mission-uploads/completions/31/image',
    );
    expect(records.first.visitedAt, DateTime.parse('2026-07-27T12:00:00Z'));
  });

  test('fetches protected mission image bytes', () async {
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<List<int>>(
                requestOptions: options,
                statusCode: 200,
                data: const [1, 2, 3],
              ),
            );
          },
        ),
      );

    final bytes = await TravelRecordRepository(
      dio: dio,
    ).fetchProtectedImage('/mission-uploads/completions/31/image');

    expect(request?.path, '/mission-uploads/completions/31/image');
    expect(request?.responseType, ResponseType.bytes);
    expect(bytes, [1, 2, 3]);
  });

  test('filters invalid record identifiers', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: const {
                  'success': true,
                  'message': '요청이 성공했습니다.',
                  'data': [
                    {
                      'visitId': 0,
                      'spotId': 20,
                      'spotName': '잘못된 기록',
                      'category': 'POTATO_CAFE',
                      'cityName': '정선군',
                      'address': '',
                      'imageUrl': null,
                      'uploadedImageUrl': null,
                      'visitedAt': '2026-07-27T12:00:00Z',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

    expect(
      await TravelRecordRepository(dio: dio).fetchTravelRecords(),
      isEmpty,
    );
  });

  test('throws ApiException when travel record response fails', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 401,
                data: const {
                  'success': false,
                  'message': '인증 정보를 확인할 수 없습니다.',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

    expect(
      () => TravelRecordRepository(dio: dio).fetchTravelRecords(),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              '인증 정보를 확인할 수 없습니다.',
            )
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });
}

const _travelRecordResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': [
    {
      'visitId': 2,
      'spotId': 20,
      'spotName': '감자 카페',
      'category': 'POTATO_CAFE',
      'cityName': '정선군',
      'address': '강원특별자치도 정선군',
      'imageUrl': 'https://example.com/cafe.png',
      'uploadedImageUrl': '/mission-uploads/completions/31/image',
      'visitedAt': '2026-07-27T12:00:00Z',
    },
    {
      'visitId': 1,
      'spotId': 10,
      'spotName': '정선 5일장',
      'category': 'POTATO_MARKET',
      'cityName': '정선군',
      'address': '강원특별자치도 정선군',
      'imageUrl': null,
      'uploadedImageUrl': null,
      'visitedAt': '2026-07-26T09:00:00Z',
    },
  ],
};
