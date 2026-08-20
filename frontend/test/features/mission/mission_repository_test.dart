import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/mission/data/mission_repository.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';

void main() {
  test('fetches missions from API and maps backend enum values', () async {
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
                data: _missionListResponse,
              ),
            );
          },
        ),
      );

    final result = await MissionRepository(dio: dio).fetchMissions();

    expect(requestedPaths, ['/missions']);
    expect(result, hasLength(2));
    expect(result.first.id, '1002');
    expect(result.first.type, MissionType.photoOcr);
    expect(result.first.status, MissionStatus.ready);
    expect(result.first.rewardType, MissionRewardType.potato);
    expect(result.first.isNew, isTrue);
    expect(result.last.status, MissionStatus.completed);
    expect(result.last.progress, result.last.target);
  });

  test('verifies mission and maps reward response', () async {
    final requestedPaths = <String>[];
    final requestBodies = <Object?>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            requestBodies.add(options.data);
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _missionCompleteResponse,
              ),
            );
          },
        ),
      );

    final result = await MissionRepository(dio: dio).verifyMission(
      '1004',
      const MissionVerificationPayload(
        type: MissionType.quiz,
        answer: '곤드레감자',
      ),
    );

    expect(requestedPaths, ['/missions/1004/verify']);
    expect(requestBodies.single, {
      'type': 'QUIZ',
      'answer': '곤드레감자',
    });
    expect(result.id, '1004');
    expect(result.rewardType, MissionRewardType.item);
    expect(result.rewardLabel, '황금감자 성장 아이템');
  });

  test('sends current location with photo mission evidence', () async {
    Object? requestBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestBody = options.data;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _missionCompleteResponse,
              ),
            );
          },
        ),
      );

    await MissionRepository(dio: dio).verifyMission(
      '1002',
      const MissionVerificationPayload(
        type: MissionType.photoOcr,
        uploadKey: 'mission-uploads/1/1002/photo.jpg',
        latitude: 37.3801,
        longitude: 128.6609,
      ),
    );

    expect(requestBody, {
      'type': 'PHOTO_OCR',
      'uploadKey': 'mission-uploads/1/1002/photo.jpg',
      'latitude': 37.3801,
      'longitude': 128.6609,
    });
  });

  test('keeps completeMission compatible with complete endpoint', () async {
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
                data: _missionCompleteResponse,
              ),
            );
          },
        ),
      );

    final result = await MissionRepository(dio: dio).completeMission('1004');

    expect(requestedPaths, ['/missions/1004/complete']);
    expect(result.id, '1004');
    expect(result.rewardType, MissionRewardType.item);
    expect(result.rewardLabel, '황금감자 성장 아이템');
  });

  test('throws ApiException from failed completion response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, Object?>>(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'success': false,
                    'message': '이미 완료한 미션입니다.',
                    'data': null,
                  },
                ),
              ),
            );
          },
        ),
      );

    expect(
      () => MissionRepository(dio: dio).verifyMission(
        '1004',
        const MissionVerificationPayload(type: MissionType.quiz),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having((error) => error.message, 'message', '이미 완료한 미션입니다.'),
      ),
    );
  });
}

const _missionListResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'totalCount': 2,
    'completedCount': 1,
    'missions': [
      {
        'missionId': 1002,
        'code': 'MISSION_GANGNEUNG_PHOTO',
        'group': 'JUMSOONI',
        'type': 'PHOTO_OCR',
        'status': 'READY',
        'title': '안목 해변에서 하지감자 찾기',
        'spotName': '안목 커피거리',
        'cityName': '강릉시',
        'description': '안목 커피거리 가맹점 매장 영수증 또는 간판을 촬영하세요.',
        'dialogue': '여가 그 유명한 안목 커피거리다 얘!',
        'conditionLabel': '영수증 또는 간판 사진 인증',
        'rewardType': 'POTATO',
        'rewardLabel': '하지감자 씨앗',
        'progress': 0,
        'target': 1,
        'active': true,
        'new': true,
        'completed': false,
        'completedAt': null,
      },
      {
        'missionId': 1004,
        'code': 'MISSION_JEONGSEON_QUIZ',
        'group': 'JUMSOONI',
        'type': 'QUIZ',
        'status': 'READY',
        'title': '정선 5일장 곤드레 퀴즈',
        'spotName': '정선 5일장',
        'cityName': '정선군',
        'description': '정선 장터에서 점순이가 내는 향토 음식 퀴즈를 풀어보세요.',
        'dialogue': '곤드레감자가 뭔지도 모르는 눈치네?',
        'conditionLabel': '정선 5일장 방문 후 퀴즈 정답 맞히기',
        'rewardType': 'ITEM',
        'rewardLabel': '황금감자 성장 아이템',
        'progress': 1,
        'target': 1,
        'active': true,
        'new': false,
        'completed': true,
        'completedAt': '2026-07-02T00:00:00Z',
      },
    ],
  },
};

const _missionCompleteResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'missionId': 1004,
    'verified': true,
    'completed': true,
    'completedAt': '2026-07-02T00:00:00Z',
    'rewardType': 'ITEM',
    'rewardLabel': '황금감자 성장 아이템',
  },
};
