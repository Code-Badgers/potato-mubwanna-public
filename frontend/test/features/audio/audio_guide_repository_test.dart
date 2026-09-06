import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/audio/data/audio_guide_repository.dart';

void main() {
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('maps $type to retryable failure with audio-only timeouts', () async {
      final dio = Dio()
        ..interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.sendTimeout, const Duration(seconds: 3));
            expect(options.receiveTimeout, const Duration(seconds: 8));
            handler.reject(DioException(requestOptions: options, type: type));
          },
        ));
      await expectLater(
        AudioGuideRepository(dio: dio).fetchAudioGuide('17'),
        throwsA(isA<AudioGuideException>()
            .having(
                (e) => e.type, 'type', AudioGuideFailureType.serviceUnavailable)
            .having((e) => e.message, 'message', contains('방문 인증은 계속'))),
      );
      expect(dio.options.receiveTimeout, isNull);
    });
  }

  for (final status in [502, 503, 504]) {
    test('gateway $status does not imply missing audio', () {
      final error = AudioGuideException.fromStatus(status, '');
      expect(error.type, AudioGuideFailureType.serviceUnavailable);
      expect(error.message, contains('다시 시도'));
    });
  }

  test('fetches and maps audio guide', () async {
    final requestedPaths = <String>[];
    final dio = _dioWithResponse(
      statusCode: 200,
      data: _audioGuideResponse,
      requestedPaths: requestedPaths,
    );

    final guide = await AudioGuideRepository(dio: dio).fetchAudioGuide('1');

    expect(requestedPaths, ['/audio-guides/spots/1']);
    expect(guide.id, 7);
    expect(guide.title, '정선 5일장 이야기');
    expect(guide.audioUrl, 'https://example.com/audio.mp3');
    expect(guide.characterScript, '점순이: 정선 5일장 이야기를 들어봐요!');
  });

  test('preserves unavailable response as a typed failure', () async {
    final dio = _dioWithResponse(
      statusCode: 404,
      data: const {
        'success': false,
        'message': '이 관광지의 오디오 가이드를 찾을 수 없습니다.',
        'data': null,
      },
    );

    expect(
      () => AudioGuideRepository(dio: dio).fetchAudioGuide('1'),
      throwsA(
        isA<AudioGuideException>().having(
          (error) => error.type,
          'type',
          AudioGuideFailureType.unavailable,
        ),
      ),
    );
  });

  test('preserves external service failure for retry UI', () async {
    final dio = _dioWithResponse(
      statusCode: 503,
      data: const {
        'success': false,
        'message': '오디오 가이드 제공 서비스에 연결할 수 없습니다.',
        'data': null,
      },
    );

    expect(
      () => AudioGuideRepository(dio: dio).fetchAudioGuide('1'),
      throwsA(
        isA<AudioGuideException>().having(
          (error) => error.type,
          'type',
          AudioGuideFailureType.serviceUnavailable,
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

const _audioGuideResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'id': 7,
    'title': '정선 5일장 이야기',
    'audioUrl': 'https://example.com/audio.mp3',
    'script': '정선 5일장은 오랜 역사를 지닌 전통시장입니다.',
    'characterScript': '점순이: 정선 5일장 이야기를 들어봐요!',
  },
};
