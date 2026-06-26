import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mypage/data/user_profile_repository.dart';

void main() {
  test('fetches the authenticated user profile', () async {
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
                    'userId': 1,
                    'nickname': '감자여행자',
                    'email': 'user@example.com',
                    'profileImage': 'https://example.com/profile.png',
                    'createdAt': '2026-06-23T00:00:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

    final profile = await UserProfileRepository(dio: dio).fetchProfile();

    expect(requestedPaths, contains('/users/me'));
    expect(profile.userId, 1);
    expect(profile.nickname, '감자여행자');
    expect(profile.email, 'user@example.com');
    expect(profile.profileImage, 'https://example.com/profile.png');
    expect(profile.createdAt, DateTime.parse('2026-06-23T00:00:00Z'));
  });

  test('treats a missing profile image as absent', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '요청이 성공했습니다.',
                  'data': {
                    'userId': 1,
                    'nickname': '감자여행자',
                    'email': 'user@example.com',
                    'profileImage': '',
                    'createdAt': '2026-06-23T00:00:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

    final profile = await UserProfileRepository(dio: dio).fetchProfile();

    expect(profile.hasProfileImage, isFalse);
  });
}
