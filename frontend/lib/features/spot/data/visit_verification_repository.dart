import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/visit_verification.dart';

class VisitVerificationRepository {
  const VisitVerificationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<VisitVerificationResult> verifyVisit(
    VisitVerificationRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.visitVerify,
        data: request.toJson(),
      );
      final result = ApiResponse<VisitVerificationResult>.fromJson(
        response.data ?? const <String, dynamic>{},
        VisitVerificationResult.fromJson,
      );
      if (!result.success || result.data == null) {
        throw ApiException(
          message:
              result.message.isEmpty ? '방문 인증에 실패했습니다.' : result.message,
          code: result.code,
          statusCode: response.statusCode,
        );
      }
      return result.data!;
    } on DioException catch (error) {
      final data = error.response?.data;
      final isNetworkFailure = error.response == null;
      throw ApiException(
        message: isNetworkFailure
            ? '네트워크 연결을 확인한 뒤 다시 시도해주세요.'
            : data is Map<String, dynamic>
                ? data['message'] as String? ?? '방문 인증에 실패했습니다.'
                : '방문 인증에 실패했습니다.',
        code: data is Map<String, dynamic> ? data['code'] as String? : null,
        statusCode: error.response?.statusCode,
      );
    }
  }
}
