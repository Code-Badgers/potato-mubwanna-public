import 'dart:async';

import '../../../core/storage/token_storage.dart';
import '../data/push_token_repository.dart';
import '../domain/push_message.dart';
import 'push_messaging_client.dart';

abstract interface class PushTokenLifecycle {
  Future<void> synchronize();

  Future<void> unregister();
}

class NoopPushTokenLifecycle implements PushTokenLifecycle {
  const NoopPushTokenLifecycle();

  @override
  Future<void> synchronize() async {}

  @override
  Future<void> unregister() async {}
}

class PushNotificationService implements PushTokenLifecycle {
  PushNotificationService({
    required PushMessagingClient messagingClient,
    required PushTokenRepository pushTokenRepository,
    required PushTokenStore pushTokenStore,
  })  : _messagingClient = messagingClient,
        _pushTokenRepository = pushTokenRepository,
        _pushTokenStore = pushTokenStore;

  final PushMessagingClient _messagingClient;
  final PushTokenRepository _pushTokenRepository;
  final PushTokenStore _pushTokenStore;

  StreamSubscription<String>? _tokenRefreshSubscription;
  // Refresh 등록 뒤에 로그아웃 삭제가 오도록 token lifecycle 작업을 직렬화한다.
  Future<void> _operationQueue = Future.value();

  bool get isAvailable => _messagingClient.isAvailable;

  Stream<PushMessage> get foregroundMessages =>
      _messagingClient.foregroundMessages;

  Stream<PushMessage> get openedMessages => _messagingClient.openedMessages;

  Future<PushMessage?> getInitialMessage() {
    return _messagingClient.getInitialMessage();
  }

  Future<void> _start() async {
    if (!isAvailable || _tokenRefreshSubscription != null) {
      return;
    }
    _tokenRefreshSubscription = _messagingClient.tokenRefreshes.listen(
      (token) => unawaited(_enqueue(() => _registerToken(token))),
    );
  }

  @override
  Future<void> synchronize() {
    return _enqueue(_synchronize);
  }

  Future<void> _synchronize() async {
    if (!isAvailable) {
      return;
    }
    final authorization = await _messagingClient.authorizationStatus();
    if (!authorization.canReceive) {
      await _unregister();
      return;
    }

    await _messagingClient.setAutoInitEnabled(true);
    await _start();
    final token = await _messagingClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _registerToken(token);
  }

  @override
  Future<void> unregister() {
    return _enqueue(_unregister);
  }

  Future<void> _unregister() async {
    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      final registeredToken = await _pushTokenStore.readRegisteredPushToken();
      if (registeredToken != null && registeredToken.isNotEmpty) {
        await _pushTokenRepository.delete(registeredToken);
      }
    } finally {
      try {
        if (isAvailable) {
          await _messagingClient.deleteToken();
        }
      } finally {
        try {
          if (isAvailable) {
            await _messagingClient.setAutoInitEnabled(false);
          }
        } finally {
          await _pushTokenStore.clearRegisteredPushToken();
        }
      }
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.catchError((_) {});
    return result;
  }

  Future<void> _registerToken(String token) async {
    if (token.isEmpty || _messagingClient.platform == null) {
      return;
    }
    final previousToken = await _pushTokenStore.readRegisteredPushToken();
    try {
      await _pushTokenRepository.register(
        token: token,
        platform: _messagingClient.platform!.apiValue,
        previousToken: previousToken,
      );
      await _pushTokenStore.saveRegisteredPushToken(token);
    } catch (_) {
      // 로그인 전 refresh 또는 일시적인 네트워크 실패는 다음 동기화에서 재시도한다.
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _operationQueue;
  }
}
