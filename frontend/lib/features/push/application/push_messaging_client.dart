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
