import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/stamp/data/stamp_repository.dart';

void main() {
  test('fetches stamp progress and next reward from separate APIs', () async {
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
                data: options.path == '/stamps/me'
                    ? _stampBookResponse
                    : _rewardResponse,
              ),
            );
          },
        ),
      );

    final result = await StampRepository(dio: dio).fetchStampBook();

    expect(
        requestedPaths, containsAll(['/stamps/me', '/stamps/rewards/check']));
    expect(result.progress.totalCount, 18);
    expect(result.progress.acquiredCount, 8);
    expect(result.progress.stamps.first.cityName, '강릉시');
    expect(result.progress.stamps.first.acquired, isTrue);
    expect(
      result.progress.stamps.first.acquiredAt,
      DateTime.parse('2026-06-30T00:00:00Z'),
    );
    expect(result.nextReward.nextTargetCount, 12);
    expect(result.nextReward.remainingCount, 4);
    expect(result.nextReward.completed, isFalse);
  });

  test('throws ApiException when a rallybook response fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': false,
                  'message': '랠리북을 불러오지 못했습니다.',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

    expect(
      () => StampRepository(dio: dio).fetchStampBook(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '랠리북을 불러오지 못했습니다.',
        ),
      ),
    );
  });
}

const _stampBookResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'totalCount': 18,
    'acquiredCount': 8,
    'stamps': [
      {
        'stampId': 1,
        'cityName': '강릉시',
        'stampName': '하지감자',
        'stampImage': null,
        'acquired': true,
        'acquiredAt': '2026-06-30T00:00:00Z',
      },
      {
        'stampId': 2,
        'cityName': '정선군',
        'stampName': '곤드레감자',
        'stampImage': null,
        'acquired': false,
        'acquiredAt': null,
      },
    ],
  },
};

const _rewardResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'acquiredCount': 8,
    'nextTargetCount': 12,
    'remainingCount': 4,
    'completed': false,
  },
};
