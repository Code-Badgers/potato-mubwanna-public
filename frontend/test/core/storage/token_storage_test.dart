import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';

void main() {
  test('읽을 수 없는 보안 저장소를 비우고 세션 없음으로 복구한다', () async {
    final storage = _UnreadableSecureStorage();
    final tokenStorage = TokenStorage(storage);

    expect(await tokenStorage.readAccessToken(), isNull);
    expect(storage.deleteAllCallCount, 1);
  });

  test('보안 저장소 정리도 실패하면 세션 없음으로 계속 진행한다', () async {
    final storage = _UnreadableSecureStorage(deleteAllFails: true);
    final tokenStorage = TokenStorage(storage);

    expect(await tokenStorage.readRefreshToken(), isNull);
    expect(storage.deleteAllCallCount, 1);
  });
}

class _UnreadableSecureStorage extends FlutterSecureStorage {
  _UnreadableSecureStorage({this.deleteAllFails = false});

  final bool deleteAllFails;
  int deleteAllCallCount = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw StateError('unreadable encrypted data');
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deleteAllCallCount++;
    if (deleteAllFails) {
      throw StateError('unable to clear encrypted data');
    }
  }
}
