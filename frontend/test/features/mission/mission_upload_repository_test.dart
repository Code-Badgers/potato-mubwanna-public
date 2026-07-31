import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/mission/data/mission_upload_repository.dart';

void main() {
  test('requests server-issued mission photo upload key as multipart',
      () async {
    final requestedPaths = <String>[];
    FormData? requestBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            requestBody = options.data as FormData;
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: _uploadResponse,
              ),
            );
          },
        ),
      );

    final result = await MissionUploadRepository(dio: dio).uploadPhoto(
      missionId: '1002',
      file: XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'receipt.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    expect(requestedPaths, ['/mission-uploads']);
    expect(requestBody?.fields.single.key, 'missionId');
    expect(requestBody?.fields.single.value, '1002');
    expect(requestBody?.files.single.key, 'file');
    expect(requestBody?.files.single.value.filename, isNotEmpty);
    expect(
        requestBody?.files.single.value.contentType.toString(), 'image/jpeg');
    expect(result.uploadKey, 'mission-uploads/1/1002/receipt.jpg');
    expect(result.fileName, 'receipt.jpg');
  });

  test('throws ApiException when upload key request is rejected', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, Object?>>(
                  requestOptions: options,
                  statusCode: 400,
                  data: {
                    'success': false,
                    'message': '지원하지 않는 이미지 형식입니다.',
                    'data': null,
                  },
                ),
              ),
            );
          },
        ),
      );

    expect(
      () => MissionUploadRepository(dio: dio).uploadPhoto(
        missionId: '1002',
        file: XFile.fromData(
          Uint8List.fromList([1]),
          name: 'receipt.gif',
          mimeType: 'image/gif',
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '지원하지 않는 이미지 형식입니다.',
        ),
      ),
    );
  });
}

const _uploadResponse = <String, Object?>{
  'success': true,
  'message': '요청이 성공했습니다.',
  'data': {
    'uploadKey': 'mission-uploads/1/1002/receipt.jpg',
    'fileName': 'receipt.jpg',
    'contentType': 'image/jpeg',
    'size': 3,
    'expiresAt': '2026-07-29T08:30:00Z',
  },
};
