import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/admin_notice.dart';

class AdminNoticeRepository {
  const AdminNoticeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<AdminNotice>> fetchNotices() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiPaths.adminNotices),
      fallbackMessage: '관리자 공지 목록을 불러오지 못했습니다.',
    );
    return _requireData<List<AdminNotice>>(
      response,
      (json) {
        final data = json as Map<String, dynamic>? ?? const {};
        final items = data['items'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(AdminNotice.fromJson)
            .toList(growable: false);
      },
      fallbackMessage: '관리자 공지 목록을 불러오지 못했습니다.',
    );
  }

  Future<AdminNotice> createNotice({
    required String title,
    required String content,
    required bool published,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiPaths.adminNotices,
        data: {'title': title, 'content': content, 'published': published},
      ),
      fallbackMessage: '공지를 등록하지 못했습니다.',
    );
    return _requireData<AdminNotice>(
      response,
      (json) => AdminNotice.fromJson(json as Map<String, dynamic>),
      fallbackMessage: '공지를 등록하지 못했습니다.',
    );
  }

  Future<AdminNotice> updateNotice({
    required int noticeId,
    required String title,
    required String content,
  }) async {
    final response = await _request(
      () => _dio.put<Map<String, dynamic>>(
        ApiPaths.adminNotice(noticeId),
        data: {'title': title, 'content': content},
      ),
      fallbackMessage: '공지를 수정하지 못했습니다.',
    );
    return _requireData<AdminNotice>(
      response,
      (json) => AdminNotice.fromJson(json as Map<String, dynamic>),
      fallbackMessage: '공지를 수정하지 못했습니다.',
    );
  }

  Future<AdminNotice> changePublication({
    required int noticeId,
    required bool published,
  }) async {
    final response = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiPaths.adminNoticePublication(noticeId),
        data: {'published': published},
      ),
      fallbackMessage: '게시 상태를 변경하지 못했습니다.',
    );
    return _requireData<AdminNotice>(
      response,
      (json) => AdminNotice.fromJson(json as Map<String, dynamic>),
      fallbackMessage: '게시 상태를 변경하지 못했습니다.',
    );
  }

  Future<Response<Map<String, dynamic>>> _request(
    Future<Response<Map<String, dynamic>>> Function() request, {
    required String fallbackMessage,
  }) async {
    try {
      return await request();
    } on DioException catch (error) {
      final data = error.response?.data;
      final message =
          data is Map<String, dynamic> ? data['message'] as String? : null;
      throw ApiException(
        message:
            message?.trim().isNotEmpty == true ? message! : fallbackMessage,
        statusCode: error.response?.statusCode,
      );
    }
  }

  T _requireData<T>(
    Response<Map<String, dynamic>> response,
    T Function(Object? json) fromData, {
    required String fallbackMessage,
  }) {
    final result = ApiResponse<T>.fromJson(
      response.data ?? const <String, dynamic>{},
      fromData,
    );
    if (!result.success || result.data == null) {
      throw ApiException(
        message: result.message.isEmpty ? fallbackMessage : result.message,
        code: result.code,
        statusCode: response.statusCode,
      );
    }
    return result.data!;
  }
}
