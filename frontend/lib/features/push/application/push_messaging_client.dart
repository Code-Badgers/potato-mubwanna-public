import '../domain/push_message.dart';

enum PushClientPlatform {
  android('ANDROID'),
  ios('IOS'),
  web('WEB');

  const PushClientPlatform(this.apiValue);

  final String apiValue;
}

enum PushAuthorizationStatus {
  authorized,
  provisional,
  denied,
  notDetermined;

  bool get canReceive =>
      this == PushAuthorizationStatus.authorized ||
      this == PushAuthorizationStatus.provisional;
}

abstract interface class PushMessagingClient {
  bool get isAvailable;

  PushClientPlatform? get platform;

  Stream<String> get tokenRefreshes;

  Stream<PushMessage> get foregroundMessages;

  Stream<PushMessage> get openedMessages;

  Future<PushMessage?> getInitialMessage();

  Future<PushAuthorizationStatus> authorizationStatus();

  Future<String?> getToken();

  Future<void> deleteToken();

  Future<void> setAutoInitEnabled(bool enabled);
}

class DeferredPushMessagingClient implements PushMessagingClient {
  DeferredPushMessagingClient(Future<PushMessagingClient> client)
      : _client = client;

  final Future<PushMessagingClient> _client;
  PushMessagingClient? _resolvedClient;

  Future<PushMessagingClient> get _resolved async {
    return _resolvedClient ??= await _client;
  }

  @override
  bool get isAvailable => _resolvedClient?.isAvailable ?? true;

  @override
  PushClientPlatform? get platform => _resolvedClient?.platform;

  @override
  Stream<String> get tokenRefreshes {
    return Stream.fromFuture(_resolved).asyncExpand(
      (client) => client.tokenRefreshes,
    );
  }

  @override
  Stream<PushMessage> get foregroundMessages {
    return Stream.fromFuture(_resolved).asyncExpand(
      (client) => client.foregroundMessages,
    );
  }

  @override
  Stream<PushMessage> get openedMessages {
    return Stream.fromFuture(_resolved).asyncExpand(
      (client) => client.openedMessages,
    );
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    return (await _resolved).authorizationStatus();
  }

  @override
  Future<void> deleteToken() async {
    await (await _resolved).deleteToken();
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    return (await _resolved).getInitialMessage();
  }

  @override
  Future<String?> getToken() async {
    return (await _resolved).getToken();
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    await (await _resolved).setAutoInitEnabled(enabled);
  }
}

class DisabledPushMessagingClient implements PushMessagingClient {
  const DisabledPushMessagingClient();

  @override
  bool get isAvailable => false;

  @override
  PushClientPlatform? get platform => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    return PushAuthorizationStatus.denied;
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}
}
