import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/kakao_sdk_initializer.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/potato/application/background_step_sync.dart';
import 'features/push/data/firebase_push_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeAndroidBackgroundStepSync();
  } catch (error) {
    // 백그라운드 작업 등록 실패가 앱 실행을 막지 않게 다음 시작 때 다시 시도한다.
    debugPrint('Background step sync initialization failed: $error');
  }
  await KakaoSdkInitializer.initialize();
  final pushMessagingClient = await FirebasePushInitializer.initialize();
  runApp(
    ProviderScope(
      overrides: [
        pushMessagingClientProvider.overrideWithValue(pushMessagingClient),
      ],
      child: const PotatoMubwannaApp(),
    ),
  );
}

@pragma('vm:entry-point')
void iosHealthBackgroundSyncEntrypoint() {
  initializeIosHealthBackgroundSyncEntrypoint();
}
