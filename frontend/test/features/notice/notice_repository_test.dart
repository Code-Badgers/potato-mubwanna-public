import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/notice/data/notice_repository.dart';

void main() {
  test('fetches and maps published notices', () async {
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
                data: const {
                  'success': true,
                  'message': '요청이 성공했습니다.',
                  'data': {
                    'items': [
                      {
                        'id': 2,
                        'title': '방문 인증 안내',
                        'content': '현장에서 위치를 확인해 주세요.',
                        'publishedAt': '2026-08-20T00:00:00Z',
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );

    final notices = await NoticeRepository(dio: dio).fetchNotices();

    expect(requestedPaths, ['/notices']);
    expect(notices, hasLength(1));
    expect(notices.single.id, 2);
    expect(notices.single.title, '방문 인증 안내');
    expect(notices.single.content, '현장에서 위치를 확인해 주세요.');
    expect(notices.single.publishedAt, DateTime.parse('2026-08-20T00:00:00Z'));
  });

  test('throws ApiException when notice response fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 500,
                data: const {
                  'success': false,
                  'message': '공지 조회에 실패했습니다.',
                  'data': null,
                },
              ),
            );
          },
        ),
      );

    expect(
      () => NoticeRepository(dio: dio).fetchNotices(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '공지 조회에 실패했습니다.',
        ),
      ),
    );
  });
}
