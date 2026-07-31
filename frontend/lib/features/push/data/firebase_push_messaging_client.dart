import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../application/push_messaging_client.dart';
import '../domain/push_message.dart';

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  bool get isAvailable => true;

  @override
  PushClientPlatform get platform {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? PushClientPlatform.ios
        : PushClientPlatform.android;
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_toPushMessage);

  @override
  Stream<PushMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPushMessage);

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => PushAuthorizationStatus.authorized,
      AuthorizationStatus.provisional => PushAuthorizationStatus.provisional,
      AuthorizationStatus.denied => PushAuthorizationStatus.denied,
      AuthorizationStatus.notDetermined =>
        PushAuthorizationStatus.notDetermined,
    };
  }

  @override
  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPushMessage(message);
  }

  @override
  Future<String?> getToken() async {
    if (platform == PushClientPlatform.ios) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) {
        return null;
      }
    }
    return _messaging.getToken();
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) {
    return _messaging.setAutoInitEnabled(enabled);
  }

  PushMessage _toPushMessage(RemoteMessage message) {
    return PushMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}
