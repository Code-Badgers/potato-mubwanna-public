import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/notice.dart';

class NoticeRepository {
  const NoticeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Notice>> fetchNotices() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.notices);
    final result = ApiResponse<List<Notice>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
        final items = data['items'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(Notice.fromJson)
            .toList(growable: false);
      },
    );
    if (!result.success || result.data == null) {
      throw ApiException(
        message: result.message.isEmpty ? '공지사항을 불러오지 못했습니다.' : result.message,
        code: result.code,
        statusCode: response.statusCode,
      );
    }
    return result.data!;
  }
}
