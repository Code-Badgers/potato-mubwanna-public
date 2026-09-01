import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/kakao_sdk_initializer.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/potato/application/background_step_sync.dart';
import 'features/push/application/push_messaging_client.dart';
import 'features/push/data/firebase_push_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // callback 등록은 비동기 Firebase 초기화와 달리 첫 프레임을 막지 않는다.
  FirebasePushInitializer.registerBackgroundHandler();
  final pushMessagingClient = Completer<PushMessagingClient>();
  runApp(
    ProviderScope(
      overrides: [
        pushMessagingClientProvider.overrideWithValue(
          DeferredPushMessagingClient(pushMessagingClient.future),
        ),
      ],
      child: const PotatoMubwannaApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePushMessaging(pushMessagingClient));
    unawaited(_initializeKakaoSdk());
    unawaited(_initializeBackgroundStepSync());
  });
}

Future<void> _initializePushMessaging(
  Completer<PushMessagingClient> completer,
) async {
  final client = await FirebasePushInitializer.initialize();
  if (!completer.isCompleted) {
    completer.complete(client);
  }
}

Future<void> _initializeKakaoSdk() async {
  try {
    await KakaoSdkInitializer.initialize();
  } catch (error) {
    developer.log(
      'Kakao SDK deferred initialization failed '
      '(type=${error.runtimeType}).',
      name: 'startup',
    );
  }
}

Future<void> _initializeBackgroundStepSync() async {
  try {
    await initializeAndroidBackgroundStepSync();
  } catch (error) {
    // 백그라운드 작업 등록 실패가 앱 실행을 막지 않게 다음 시작 때 다시 시도한다.
    developer.log(
      'Background step sync registration failed '
      '(type=${error.runtimeType}).',
      name: 'startup',
    );
  }
}
