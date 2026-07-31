import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/kakao_sdk_initializer.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/push/data/firebase_push_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
