import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mypage/data/user_activity_summary_repository.dart';

void main() {
  test('fetches the authenticated user activity summary', () async {
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
                data: {
                  'success': true,
                  'message': '요청이 성공했습니다.',
                  'data': {
                    'totalSteps': 256842,
                    'stampCount': 12,
                    'ownedPotatoCount': 7,
                  },
                },
              ),
            );
          },
        ),
      );

    final summary = await UserActivitySummaryRepository(
      dio: dio,
    ).fetchActivitySummary();

    expect(requestedPaths, contains('/users/me/activity-summary'));
    expect(summary.totalSteps, 256842);
    expect(summary.stampCount, 12);
    expect(summary.ownedPotatoCount, 7);
  });
}
