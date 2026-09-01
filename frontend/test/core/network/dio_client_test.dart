import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/dio_client.dart';
import 'package:potato_mubwanna/core/network/network_timeouts.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';

void main() {
  test('applies bounded timeouts to the shared network client', () {
    final client = DioClient(
      tokenStorage: const TokenStorage(FlutterSecureStorage()),
      baseUrl: 'https://api.example.com',
    );

    expect(client.dio.options.connectTimeout, NetworkTimeouts.connect);
    expect(client.dio.options.sendTimeout, NetworkTimeouts.send);
    expect(client.dio.options.receiveTimeout, NetworkTimeouts.receive);
  });

  test('allows shorter timeouts for startup-sensitive requests', () {
    const connectTimeout = Duration(seconds: 2);
    const sendTimeout = Duration(seconds: 3);
    const receiveTimeout = Duration(seconds: 4);
    final client = DioClient(
      tokenStorage: const TokenStorage(FlutterSecureStorage()),
      baseUrl: 'https://api.example.com',
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );

    expect(client.dio.options.connectTimeout, connectTimeout);
    expect(client.dio.options.sendTimeout, sendTimeout);
    expect(client.dio.options.receiveTimeout, receiveTimeout);
  });
}
