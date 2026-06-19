import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    String baseUrl = '/api',
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage,
        baseUrl: baseUrl,
        dio: dio,
      ),
    );
  }

  final Dio dio;
}
