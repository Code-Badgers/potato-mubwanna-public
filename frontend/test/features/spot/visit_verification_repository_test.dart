import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/spot/data/visit_verification_repository.dart';
import 'package:potato_mubwanna/features/spot/domain/visit_verification.dart';

void main() {
  test('verifies visit and maps acquired potato result', () async {
    final requests = <Map<String, Object?>>[];
    final dio = _dioWithResponse(
      statusCode: 200,
      data: _successResponse,
      requests: requests,
    );

    final result = await VisitVerificationRepository(dio: dio).verifyVisit(
      const VisitVerificationRequest(
        spotId: '1',
        latitude: 37.3801,
        longitude: 128.6609,
      ),
    );

    expect(requests.single['path'], '/visits/verify');
    expect(result.verified, isTrue);
    expect(result.stampIssued, isTrue);
    expect(result.potatoAcquired, isTrue);
    expect(result.acquiredPotato?.name, '황금감자');
    expect(result.acquiredPotato?.rarityLabel, '영웅');
    expect(result.acquiredPotato?.alreadyOwned, isFalse);
  });

  test('throws ApiException with backend message when verification fails',
      () async {
    final dio = _dioWithError(
      statusCode: 409,
      data: const {
        'success': false,
        'message': '이미 방문 인증한 감자 스팟입니다.',
      },
    );

    expect(
      () => VisitVerificationRepository(dio: dio).verifyVisit(
        const VisitVerificationRequest(
          spotId: '1',
          latitude: 37.3801,
          longitude: 128.6609,
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              '이미 방문 인증한 감자 스팟입니다.',
            ),
      ),
    );
  });
}

Dio _dioWithResponse({
  required int statusCode,
  required Map<String, Object?> data,
  required List<Map<String, Object?>> requests,
}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add({
            'path': options.path,
            'data': options.data,
          });
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

Dio _dioWithError({
  required int statusCode,
  required Map<String, Object?> data,
}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: statusCode,
                data: data,
              ),
            ),
          );
        },
      ),
    );
}

const _successResponse = <String, Object?>{
  'success': true,
  'message': '방문 인증이 완료되었습니다.',
  'data': {
    'spotId': 1,
    'verified': true,
    'distanceMeters': 23.5,
    'verificationRadiusMeter': 100,
    'stampIssued': true,
    'potatoAcquired': true,
    'acquiredPotato': {
      'potatoId': 3,
      'code': 'POTATO_GOLDEN_GANGWON',
      'name': '황금감자',
      'region': '강원특별자치도',
      'rarity': 'EPIC',
      'alreadyOwned': false,
    },
    'missionAvailable': false,
  },
};
