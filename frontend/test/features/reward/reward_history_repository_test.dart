import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/reward/data/reward_history_repository.dart';
import 'package:potato_mubwanna/features/reward/domain/reward_history.dart';

void main() {
  test('fetches and maps reward history', () async {
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
                data: _rewardHistoryResponse,
              ),
            );
          },
        ),
      );

    final rewards = await RewardHistoryRepository(
      dio: dio,
    ).fetchRewardHistory();

    expect(requestedPaths, ['/rewards/history']);
    expect(rewards, hasLength(3));
    expect(rewards.first.rewardHistoryId, 3);
    expect(rewards.first.rewardType, RewardType.coupon);
    expect(rewards.first.sourceType, RewardSourceType.stamp);
    expect(rewards.first.sourceId, 6);
    expect(rewards.first.createdAt, DateTime.parse('2026-07-17T09:00:00Z'));
    expect(rewards[1].rewardType, RewardType.potato);
    expect(rewards[1].sourceType, RewardSourceType.mission);
    expect(rewards.last.rewardType, RewardType.item);
    expect(rewards.last.sourceType, RewardSourceType.event);
  });

  test('throws ApiException when reward history response fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
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
      () => RewardHistoryRepository(dio: dio).fetchRewardHistory(),
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

const _rewardHistoryResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'rewards': [
      {
        'rewardHistoryId': 3,
        'rewardType': 'COUPON',
        'rewardName': '강원 감자 제휴점 3,000원 할인권',
        'sourceType': 'STAMP',
        'sourceId': 6,
        'createdAt': '2026-07-17T09:00:00Z',
      },
      {
        'rewardHistoryId': 2,
        'rewardType': 'POTATO',
        'rewardName': '수미감자 씨앗',
        'sourceType': 'MISSION',
        'sourceId': 1001,
        'createdAt': '2026-07-16T09:00:00Z',
      },
      {
        'rewardHistoryId': 1,
        'rewardType': 'ITEM',
        'rewardName': '황금감자 성장 아이템',
        'sourceType': 'EVENT',
        'sourceId': 7,
        'createdAt': '2026-07-15T09:00:00Z',
      },
    ],
  },
};
