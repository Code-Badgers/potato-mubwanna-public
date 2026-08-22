import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/stamp/data/stamp_repository.dart';
import 'package:potato_mubwanna/features/stamp/domain/stamp_book.dart';

void main() {
  test('legacy reward status without claim fields stays non-claimable', () {
    final reward = NextStampReward.fromJson(const {
      'acquiredCount': 8,
      'nextTargetCount': 12,
      'remainingCount': 4,
      'completed': false,
    });

    expect(reward.claimable, isFalse);
    expect(reward.claimableTargetCount, isNull);
    expect(reward.canClaim, isFalse);
  });

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
      requestedPaths,
      containsAll(['/stamps/me', '/stamps/rewards/check']),
    );
    expect(result.progress.totalCount, 29);
    expect(result.progress.stamps.first.spotId, 101);
    expect(result.progress.stamps.first.stampName, '경포대');
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
    expect(result.nextReward.claimable, isTrue);
    expect(result.nextReward.claimableTargetCount, 6);
  });

  test('fetches and maps the next stamp targets', () async {
    String? requestedPath;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _nextTargetsResponse,
              ),
            );
          },
        ),
      );

    final result = await StampRepository(dio: dio).fetchNextTargets();

    expect(requestedPath, '/stamps/me/next-targets');
    expect(result, hasLength(2));
    expect(result.first.spotId, 101);
    expect(result.first.spotName, '정선 5일장');
    expect(result.first.cityName, '정선군');
    expect(result.first.categoryLabel, '시장·상권');
  });

  test('fetches rallybook spots with official coordinates', () async {
    String? requestedPath;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _rallybookSpotsResponse,
              ),
            );
          },
        ),
      );

    final result = await StampRepository(dio: dio).fetchRallybookSpots();

    expect(requestedPath, '/stamps/rallybook-spots');
    expect(result, hasLength(2));
    expect(result.first.spotName, '남이섬');
    expect(result.first.latitude, 37.7962651);
    expect(result.first.longitude, 127.5254892);
    expect(result.last.spotName, '소양강 스카이워크');
  });

  test(
    'claims the lowest available reward and maps the issued coupon',
    () async {
      String? requestedPath;
      Object? requestData;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedPath = options.path;
              requestData = options.data;
              handler.resolve(
                Response<Map<String, Object?>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _claimResponse,
                ),
              );
            },
          ),
        );

      final result = await StampRepository(
        dio: dio,
      ).claimReward(const StampRewardClaimRequest(targetCount: 6));

      expect(requestedPath, '/stamps/rewards/claim');
      expect(requestData, {'targetCount': 6});
      expect(result.targetCount, 6);
      expect(result.rewardHistoryId, 10);
      expect(result.userCouponId, 21);
      expect(result.couponName, '강원 감자 제휴점 3,000원 할인권');
      expect(result.expiresAt, DateTime.parse('2026-08-16T00:00:00Z'));
    },
  );

  test('maps reward claim API errors to ApiException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 409,
                  data: const {
                    'success': false,
                    'message': '이미 수령한 스탬프 보상입니다.',
                    'data': null,
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

    expect(
      () => StampRepository(
        dio: dio,
      ).claimReward(const StampRewardClaimRequest(targetCount: 6)),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having((error) => error.message, 'message', '이미 수령한 스탬프 보상입니다.'),
      ),
    );
  });

  test('throws ApiException when a stamp tour response fails', () async {
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
                  'message': '스탬프 투어를 불러오지 못했습니다.',
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
          '스탬프 투어를 불러오지 못했습니다.',
        ),
      ),
    );
  });
}

const _stampBookResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'totalCount': 29,
    'acquiredCount': 8,
    'stamps': [
      {
        'stampId': 1,
        'spotId': 101,
        'cityName': '강릉시',
        'stampName': '경포대',
        'stampImage': null,
        'acquired': true,
        'acquiredAt': '2026-06-30T00:00:00Z',
      },
      {
        'stampId': 2,
        'spotId': 102,
        'cityName': '정선군',
        'stampName': '정선 5일장',
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
    'claimable': true,
    'claimableTargetCount': 6,
  },
};

const _nextTargetsResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': [
    {
      'spotId': 101,
      'spotName': '정선 5일장',
      'cityName': '정선군',
      'category': 'POTATO_MARKET',
      'address': '강원특별자치도 정선군',
      'imageUrl': null,
    },
    {
      'spotId': 102,
      'spotName': '평창 감자 체험장',
      'cityName': '평창군',
      'category': 'POTATO_EXPERIENCE',
      'address': '강원특별자치도 평창군',
      'imageUrl': null,
    },
  ],
};

const _claimResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'targetCount': 6,
    'rewardHistoryId': 10,
    'userCouponId': 21,
    'couponName': '강원 감자 제휴점 3,000원 할인권',
    'expiresAt': '2026-08-16T00:00:00Z',
  },
};

const _rallybookSpotsResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': [
    {
      'spotId': 101,
      'spotName': '남이섬',
      'cityName': '춘천시',
      'category': 'POTATO_TOUR',
      'latitude': 37.7962651,
      'longitude': 127.5254892,
      'address': '강원특별자치도 춘천시 남이섬길 1 남이섬',
      'imageUrl': null,
    },
    {
      'spotId': 102,
      'spotName': '소양강 스카이워크',
      'cityName': '춘천시',
      'category': 'POTATO_TOUR',
      'latitude': 37.8932774,
      'longitude': 127.7236633,
      'address': '강원특별자치도 춘천시 영서로 2663',
      'imageUrl': null,
    },
  ],
};
