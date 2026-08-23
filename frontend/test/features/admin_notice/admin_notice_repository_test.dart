import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/admin_notice/data/admin_notice_repository.dart';

void main() {
  test('fetches every notice from the admin endpoint', () async {
    final requests = <_RequestRecord>[];
    final repository = AdminNoticeRepository(
      dio: _dioWithAdminNoticeResponse(requests),
    );

    final notices = await repository.fetchNotices();

    expect(requests.single.method, 'GET');
    expect(requests.single.path, '/admin/notices');
    expect(notices, hasLength(1));
    expect(notices.single.title, '서비스 점검 안내');
    expect(notices.single.published, isFalse);
    expect(notices.single.publishedAt, isNull);
  });

  test('uses the expected write endpoints and payloads', () async {
    final requests = <_RequestRecord>[];
    final repository = AdminNoticeRepository(
      dio: _dioWithAdminNoticeResponse(requests),
    );

    await repository.createNotice(
      title: '새 공지',
      content: '새 내용',
      published: true,
    );
    await repository.updateNotice(
      noticeId: 7,
      title: '수정 공지',
      content: '수정 내용',
    );
    await repository.changePublication(noticeId: 7, published: false);

    expect(
      requests.map((request) => '${request.method} ${request.path}'),
      [
        'POST /admin/notices',
        'PUT /admin/notices/7',
        'PATCH /admin/notices/7/publication',
      ],
    );
    expect(requests[0].data, {
      'title': '새 공지',
      'content': '새 내용',
      'published': true,
    });
    expect(requests[1].data, {'title': '수정 공지', 'content': '수정 내용'});
    expect(requests[2].data, {'published': false});
  });
}

Dio _dioWithAdminNoticeResponse(List<_RequestRecord> requests) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(
            _RequestRecord(
              method: options.method,
              path: options.path,
              data: options.data,
            ),
          );
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: options.method == 'POST' ? 201 : 200,
              data: {
                'success': true,
                'message': '요청이 성공했습니다.',
                'data': options.method == 'GET'
                    ? {
                        'items': [_noticeJson],
                      }
                    : _noticeJson,
              },
            ),
          );
        },
      ),
    );
}

const _noticeJson = {
  'id': 7,
  'title': '서비스 점검 안내',
  'content': '점검 내용',
  'published': false,
  'publishedAt': null,
  'createdAt': '2026-08-23T01:00:00Z',
  'updatedAt': '2026-08-23T02:00:00Z',
};

class _RequestRecord {
  const _RequestRecord({
    required this.method,
    required this.path,
    required this.data,
  });

  final String method;
  final String path;
  final Object? data;
}
