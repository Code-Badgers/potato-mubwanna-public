import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/data/potato_repository.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';

void main() {
  test('posts a representative potato interaction and maps its result',
      () async {
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
                data: _interactionResponse,
              ),
            );
          },
        ),
      );

    final result = await PotatoRepository(dio: dio)
        .interactWithRepresentativePotato(PotatoInteractionAction.water);

    expect(request?.method, 'POST');
    expect(request?.path, '/potatoes/me/representative/interactions');
    expect(request?.data, {'action': 'WATER'});
    expect(result.potatoId, '2');
    expect(result.action, PotatoInteractionAction.water);
    expect(result.growthDistanceAdded, 120);
    expect(result.cooldownSeconds, 7200);
    expect(result.growthResult?.currentLevel, 3);
  });
}

const _interactionResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'potatoId': 2,
    'potatoName': '곤드레감자',
    'action': 'WATER',
    'growthDistanceAdded': 120.0,
    'cooldownSeconds': 7200,
    'nextAvailableAt': '2026-08-20T12:00:00Z',
    'growthResult': {
      'potatoId': 2,
      'potatoName': '곤드레감자',
      'previousLevel': 2,
      'currentLevel': 3,
      'leveledUp': true,
      'fullyGrown': false,
    },
  },
};
