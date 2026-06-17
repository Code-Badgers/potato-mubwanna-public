import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/kakao_sdk_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KakaoSdkInitializer.initialize();
  runApp(const ProviderScope(child: PotatoMubwannaApp()));
}
