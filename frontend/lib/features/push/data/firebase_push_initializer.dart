import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../app/config/app_environment.dart';
import '../application/push_messaging_client.dart';
import 'firebase_push_messaging_client.dart';

class FirebasePushInitializer {
  const FirebasePushInitializer._();

  static void registerBackgroundHandler() {
    if (!AppEnvironment.hasFirebaseMessagingConfig) {
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<PushMessagingClient> initialize() async {
    if (!AppEnvironment.hasFirebaseMessagingConfig) {
      return const DisabledPushMessagingClient();
    }

    try {
      await Firebase.initializeApp(options: _firebaseOptions());
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
      return FirebasePushMessagingClient(FirebaseMessaging.instance);
    } catch (_) {
      debugPrint('FCM 비활성화: Firebase 초기화에 실패했습니다.');
      return const DisabledPushMessagingClient();
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppEnvironment.hasFirebaseMessagingConfig || Firebase.apps.isNotEmpty) {
    return;
  }
  await Firebase.initializeApp(options: _firebaseOptions());
}

FirebaseOptions _firebaseOptions() {
  return FirebaseOptions(
    apiKey: AppEnvironment.firebaseApiKey,
    appId: AppEnvironment.firebaseAppId,
    messagingSenderId: AppEnvironment.firebaseMessagingSenderId,
    projectId: AppEnvironment.firebaseProjectId,
  );
}
