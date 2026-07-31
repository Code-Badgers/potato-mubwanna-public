import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushTokenStore {
  Future<String?> readRegisteredPushToken();

  Future<void> saveRegisteredPushToken(String token);

  Future<void> clearRegisteredPushToken();
}

class TokenStorage implements PushTokenStore {
  const TokenStorage(this._storage);

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _registeredPushTokenKey = 'registeredPushToken';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() {
    return _storage.deleteAll();
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<String?> readRegisteredPushToken() {
    return _storage.read(key: _registeredPushTokenKey);
  }

  @override
  Future<void> saveRegisteredPushToken(String token) {
    return _storage.write(key: _registeredPushTokenKey, value: token);
  }

  @override
  Future<void> clearRegisteredPushToken() {
    return _storage.delete(key: _registeredPushTokenKey);
  }
}
