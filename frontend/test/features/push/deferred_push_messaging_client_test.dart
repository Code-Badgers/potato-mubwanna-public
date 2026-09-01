import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/push/application/push_messaging_client.dart';
import 'package:potato_mubwanna/features/push/domain/push_message.dart';

void main() {
  test('waits for push initialization before forwarding method calls',
      () async {
    final initialization = Completer<PushMessagingClient>();
    final client = DeferredPushMessagingClient(initialization.future);
    final token = client.getToken();
    var hasCompleted = false;
    token.then((_) => hasCompleted = true);

    expect(client.isAvailable, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(hasCompleted, isFalse);

    final resolved = _RecordingPushMessagingClient();
    initialization.complete(resolved);

    expect(await token, 'push-token');
    expect(resolved.getTokenCalls, 1);
    expect(client.platform, PushClientPlatform.android);
  });

  test('forwards message streams after initialization completes', () async {
    final initialization = Completer<PushMessagingClient>();
    final client = DeferredPushMessagingClient(initialization.future);
    final message = client.foregroundMessages.first;
    final resolved = _RecordingPushMessagingClient();

    initialization.complete(resolved);
    resolved.foregroundController.add(
      const PushMessage(title: '여행 알림', body: null, data: {}),
    );

    expect((await message).title, '여행 알림');
    await resolved.foregroundController.close();
  });

  test('reflects a disabled client after initialization failure fallback',
      () async {
    final initialization = Completer<PushMessagingClient>();
    final client = DeferredPushMessagingClient(initialization.future);

    initialization.complete(const DisabledPushMessagingClient());

    expect(await client.getToken(), isNull);
    expect(client.isAvailable, isFalse);
    expect(client.platform, isNull);
  });
}

class _RecordingPushMessagingClient implements PushMessagingClient {
  final foregroundController = StreamController<PushMessage>();
  int getTokenCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  PushClientPlatform get platform => PushClientPlatform.android;

  @override
  Stream<PushMessage> get foregroundMessages => foregroundController.stream;

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    return PushAuthorizationStatus.authorized;
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async {
    getTokenCalls += 1;
    return 'push-token';
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}
}
