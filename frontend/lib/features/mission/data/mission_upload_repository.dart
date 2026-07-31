import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';

class MissionUploadRepository {
  const MissionUploadRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<MissionUploadResult> uploadPhoto({
    required String missionId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeOf(file);
    final formData = FormData.fromMap({
      'missionId': missionId,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: _fileNameOf(file),
        contentType: contentType,
      ),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.missionUploads,
        data: formData,
      );
      final apiResponse = ApiResponse<MissionUploadResult>.fromJson(
        response.data ?? const <String, dynamic>{},
        MissionUploadResult.fromJson,
      );
      if (!apiResponse.success || apiResponse.data == null) {
        throw ApiException(
          message: apiResponse.message.isEmpty
              ? '인증샷 업로드 키를 발급하지 못했습니다.'
              : apiResponse.message,
          code: apiResponse.code,
          statusCode: response.statusCode,
        );
      }
      return apiResponse.data!;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException(
          message: data['message'] as String? ?? '인증샷 업로드에 실패했습니다.',
          code: data['code'] as String?,
          statusCode: error.response?.statusCode,
        );
      }
      rethrow;
    }
  }

  DioMediaType _contentTypeOf(XFile file) {
    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.isNotEmpty) {
      return DioMediaType.parse(mimeType);
    }
    return MultipartFile.lookupMediaType(file.name) ??
        DioMediaType.parse('image/jpeg');
  }

  String _fileNameOf(XFile file) {
    if (file.name.isNotEmpty) {
      return file.name;
    }
    return 'mission-photo.jpg';
  }
}

class MissionUploadResult {
  const MissionUploadResult({
    required this.uploadKey,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.expiresAt,
  });

  final String uploadKey;
  final String fileName;
  final String contentType;
  final int size;
  final DateTime expiresAt;

  factory MissionUploadResult.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return MissionUploadResult(
      uploadKey: data['uploadKey'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      contentType: data['contentType'] as String? ?? '',
      size: (data['size'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
