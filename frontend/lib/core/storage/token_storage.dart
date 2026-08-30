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
    return _read(_accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _read(_refreshTokenKey);
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
    return _read(_registeredPushTokenKey);
  }

  @override
  Future<void> saveRegisteredPushToken(String token) {
    return _storage.write(key: _registeredPushTokenKey, value: token);
  }

  @override
  Future<void> clearRegisteredPushToken() {
    return _storage.delete(key: _registeredPushTokenKey);
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Android 백업에서 암호화 값만 복원되는 등 저장소를 해독할 수 없는
      // 경우에는 기존 세션을 폐기하고 비로그인 상태로 안전하게 복구한다.
      try {
        await _storage.deleteAll();
      } catch (_) {
        // 정리 실패가 공개 API 요청까지 막지 않도록 세션 없음으로 처리한다.
      }
      return null;
    }
  }
}
