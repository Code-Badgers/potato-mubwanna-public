import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'network_timeouts.dart';

class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    String baseUrl = '/api',
    Duration connectTimeout = NetworkTimeouts.connect,
    Duration sendTimeout = NetworkTimeouts.send,
    Duration receiveTimeout = NetworkTimeouts.receive,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout,
           sendTimeout: sendTimeout,
           receiveTimeout: receiveTimeout,
         ),
       ) {
    AppLogger.debug('API base: ${_safeBaseUrl(baseUrl)}', name: 'network');
    dio.interceptors.add(
      AuthInterceptor(tokenStorage, baseUrl: baseUrl, dio: dio),
    );
  }

  final Dio dio;
}

String _safeBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null) {
    return 'invalid';
  }
  if (uri.host.isEmpty) {
    return uri.path.isEmpty ? 'relative' : uri.path;
  }
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port${uri.path}';
}
