import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/spot/data/spot_detail_repository.dart';

void main() {
  test('fetches and maps spot detail', () async {
    final requestedPaths = <String>[];
    final dio = _dioWithResponse(
      statusCode: 200,
      data: _spotDetailResponse,
      requestedPaths: requestedPaths,
    );

    final detail = await SpotDetailRepository(dio: dio).fetchSpotDetail('1');

    expect(requestedPaths, ['/spots/1']);
    expect(detail.id, '1');
    expect(detail.name, '정선 5일장');
    expect(detail.categoryLabel, '시장');
    expect(detail.congestionLabel, '여유');
    expect(detail.potatoTags, ['감자', '감자전']);
    expect(detail.verificationRadiusMeter, 100);
    expect(detail.stampEnabled, isTrue);
  });

  test('throws ApiException when spot detail response fails', () async {
    final dio = _dioWithResponse(
      statusCode: 404,
      data: const {
        'success': false,
        'message': '관광지를 찾을 수 없습니다.',
        'data': null,
      },
    );

    expect(
      () => SpotDetailRepository(dio: dio).fetchSpotDetail('404'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having(
              (error) => error.message,
              'message',
              '관광지를 찾을 수 없습니다.',
            ),
      ),
    );
  });
}

Dio _dioWithResponse({
  required int statusCode,
  required Map<String, Object?> data,
  List<String>? requestedPaths,
}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths?.add(options.path);
          handler.resolve(
            Response<Map<String, Object?>>(
              requestOptions: options,
              statusCode: statusCode,
              data: data,
            ),
          );
        },
      ),
    );
}

const _spotDetailResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'id': 1,
    'contentId': '1234567',
    'name': '정선 5일장',
    'category': 'POTATO_MARKET',
    'latitude': 37.3801,
    'longitude': 128.6609,
    'address': '강원특별자치도 정선군 정선읍',
    'cityName': '정선군',
    'imageUrl': 'https://example.com/spot.jpg',
    'potatoTags': '감자, 감자전',
    'congestionLevel': 'LOW',
    'verificationRadiusMeter': 100,
    'stampEnabled': true,
  },
};
