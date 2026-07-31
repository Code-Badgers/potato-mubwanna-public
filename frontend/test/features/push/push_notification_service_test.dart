import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/push/application/push_messaging_client.dart';
import 'package:potato_mubwanna/features/push/application/push_notification_service.dart';
import 'package:potato_mubwanna/features/push/data/push_token_repository.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';

void main() {
  test('registers authorized token with previous token', () async {
    final requests = <RequestOptions>[];
    final client = _FakePushMessagingClient(
      authorization: PushAuthorizationStatus.authorized,
      currentToken: 'current-token',
    );
    final store = _MemoryPushTokenStore('previous-token');
    final service = PushNotificationService(
      messagingClient: client,
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: store,
    );

    await service.synchronize();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/users/me/push-tokens');
    expect(requests.single.data, {
      'token': 'current-token',
      'platform': 'ANDROID',
      'previousToken': 'previous-token',
    });
    expect(store.token, 'current-token');
    expect(client.autoInitValues, [true]);
    await service.dispose();
    await client.dispose();
  });

  test('registers refreshed token from Firebase stream', () async {
    final requests = <RequestOptions>[];
    final client = _FakePushMessagingClient(
      authorization: PushAuthorizationStatus.authorized,
      currentToken: 'initial-token',
    );
    final store = _MemoryPushTokenStore('initial-token');
    final service = PushNotificationService(
      messagingClient: client,
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: store,
    );
    await service.synchronize();
    requests.clear();

    client.emitRefreshedToken('refreshed-token');
    await pumpEventQueue();

    expect(requests.single.data, {
      'token': 'refreshed-token',
      'platform': 'ANDROID',
      'previousToken': 'initial-token',
    });
    expect(store.token, 'refreshed-token');
    await service.dispose();
    await client.dispose();
  });

  test('unregister waits for an in-flight token refresh', () async {
    final requests = <RequestOptions>[];
    final registrationStarted = Completer<void>();
    final releaseRegistration = Completer<void>();
    final client = _FakePushMessagingClient(
      authorization: PushAuthorizationStatus.authorized,
      currentToken: null,
    );
    final store = _MemoryPushTokenStore('previous-token');
    final service = PushNotificationService(
      messagingClient: client,
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(
          requests,
          beforeResponse: (options) async {
            if (options.method == 'POST') {
              registrationStarted.complete();
              await releaseRegistration.future;
            }
          },
        ),
      ),
      pushTokenStore: store,
    );
    await service.synchronize();

    client.emitRefreshedToken('refreshed-token');
    await registrationStarted.future;
    final unregister = service.unregister();
    releaseRegistration.complete();
    await unregister;

    expect(requests.map((request) => request.method), ['POST', 'DELETE']);
    expect(requests.last.data, {'token': 'refreshed-token'});
    expect(store.token, isNull);
    await service.dispose();
    await client.dispose();
  });

  test('revoked permission deletes backend and local Firebase tokens',
      () async {
    final requests = <RequestOptions>[];
    final client = _FakePushMessagingClient(
      authorization: PushAuthorizationStatus.denied,
      currentToken: 'registered-token',
    );
    final store = _MemoryPushTokenStore('registered-token');
    final service = PushNotificationService(
      messagingClient: client,
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: store,
    );

    await service.synchronize();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.data, {'token': 'registered-token'});
    expect(client.deleteTokenCalls, 1);
    expect(client.autoInitValues, [false]);
    expect(store.token, isNull);
    await service.dispose();
    await client.dispose();
  });

  test('disabled client does not call backend', () async {
    final requests = <RequestOptions>[];
    final service = PushNotificationService(
      messagingClient: const DisabledPushMessagingClient(),
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: _MemoryPushTokenStore(null),
    );

    await service.synchronize();
    await service.unregister();

    expect(requests, isEmpty);
  });

  test('disabled client removes a token saved by an earlier build', () async {
    final requests = <RequestOptions>[];
    final store = _MemoryPushTokenStore('stale-token');
    final service = PushNotificationService(
      messagingClient: const DisabledPushMessagingClient(),
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: store,
    );

    await service.unregister();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.data, {'token': 'stale-token'});
    expect(store.token, isNull);
  });

  test('unregister clears Firebase state when secure storage read fails',
      () async {
    final requests = <RequestOptions>[];
    final client = _FakePushMessagingClient(
      authorization: PushAuthorizationStatus.authorized,
      currentToken: 'registered-token',
    );
    final store = _FailingReadPushTokenStore();
    final service = PushNotificationService(
      messagingClient: client,
      pushTokenRepository: PushTokenRepository(
        dio: _recordingDio(requests),
      ),
      pushTokenStore: store,
    );

    await expectLater(service.unregister(), throwsStateError);

    expect(requests, isEmpty);
    expect(client.deleteTokenCalls, 1);
    expect(client.autoInitValues, [false]);
    expect(store.clearCalls, 1);
    await service.dispose();
    await client.dispose();
  });
}

Dio _recordingDio(
  List<RequestOptions> requests, {
  Future<void> Function(RequestOptions options)? beforeResponse,
}) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          await beforeResponse?.call(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'success': true,
                'message': '요청이 성공했습니다.',
                'data': null,
              },
            ),
          );
        },
      ),
    );
}

class _MemoryPushTokenStore implements PushTokenStore {
  _MemoryPushTokenStore(this.token);

  String? token;

  @override
  Future<void> clearRegisteredPushToken() async {
    token = null;
  }

  @override
  Future<String?> readRegisteredPushToken() async => token;

  @override
  Future<void> saveRegisteredPushToken(String token) async {
    this.token = token;
  }
}

class _FailingReadPushTokenStore implements PushTokenStore {
  int clearCalls = 0;

  @override
  Future<void> clearRegisteredPushToken() async {
    clearCalls++;
  }

  @override
  Future<String?> readRegisteredPushToken() {
    throw StateError('secure storage unavailable');
  }

  @override
  Future<void> saveRegisteredPushToken(String token) async {}
}

class _FakePushMessagingClient implements PushMessagingClient {
  _FakePushMessagingClient({
    required this.authorization,
    required this.currentToken,
  });

  final PushAuthorizationStatus authorization;
  final String? currentToken;
  final _tokenRefreshController = StreamController<String>.broadcast();
  final _foregroundController = StreamController<PushMessage>.broadcast();
  final _openedController = StreamController<PushMessage>.broadcast();

  int deleteTokenCalls = 0;
  final autoInitValues = <bool>[];

  @override
  bool get isAvailable => true;

  @override
  PushClientPlatform get platform => PushClientPlatform.android;

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Stream<PushMessage> get openedMessages => _openedController.stream;

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async => authorization;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
  }

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async => currentToken;

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    autoInitValues.add(enabled);
  }

  void emitRefreshedToken(String token) {
    _tokenRefreshController.add(token);
  }

  Future<void> dispose() async {
    await _tokenRefreshController.close();
    await _foregroundController.close();
    await _openedController.close();
  }
}
