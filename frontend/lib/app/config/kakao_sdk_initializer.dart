import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app_environment.dart';

class KakaoSdkInitializer {
  const KakaoSdkInitializer._();

  static Future<void>? _initialization;

  static Future<void> initialize() async {
    final activeInitialization = _initialization;
    if (activeInitialization != null) {
      return activeInitialization;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }
  }

  static Future<void> _initialize() async {
    if (!AppEnvironment.hasKakaoLoginKey &&
        AppEnvironment.kakaoJavaScriptKey.isEmpty) {
      return;
    }

    await KakaoSdk.init(
      nativeAppKey: AppEnvironment.kakaoNativeAppKey.isEmpty
          ? null
          : AppEnvironment.kakaoNativeAppKey,
      javaScriptAppKey: AppEnvironment.kakaoJavaScriptKey.isEmpty
          ? null
          : AppEnvironment.kakaoJavaScriptKey,
      customScheme: AppEnvironment.kakaoNativeAppKey.isEmpty
          ? null
          : 'kakao${AppEnvironment.kakaoNativeAppKey}',
    );
  }
}
