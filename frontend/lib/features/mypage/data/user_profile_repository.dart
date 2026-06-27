import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/user_profile.dart';

class UserProfileRepository {
  const UserProfileRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myProfile);
    final apiResponse = ApiResponse<UserProfile>.fromJson(
      response.data ?? const <String, dynamic>{},
      UserProfile.fromJson,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message.isEmpty
            ? '내 정보를 불러오지 못했습니다.'
            : apiResponse.message,
        code: apiResponse.code,
        statusCode: response.statusCode,
      );
    }

    return apiResponse.data!;
  }
}
