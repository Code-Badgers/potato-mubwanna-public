// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import '../../../app/config/app_environment.dart';
import 'kakao_login_exception.dart';

class KakaoLoginService {
  const KakaoLoginService();

  static const _sdkElementId = 'kakao-js-sdk';
  static const _sdkUrl =
      'https://t1.kakaocdn.net/kakao_js_sdk/2.7.5/kakao.min.js';
  static const _profileConsentScope = 'profile_nickname,account_email';

  Future<void> preload() async {
    if (AppEnvironment.kakaoJavaScriptKey.isEmpty) {
      return;
    }

    await _loadSdk();
    _initializeSdk();
  }

  Future<String> loginAndReadAccessToken() async {
    if (AppEnvironment.kakaoJavaScriptKey.isEmpty) {
      throw const KakaoLoginUnsupportedException(
        'KAKAO_JAVASCRIPT_KEY가 설정되지 않았습니다.',
      );
    }

    await _loadSdk();
    _initializeSdk();
    return _loginWithPopup();
  }

  Future<void> _loadSdk() {
    final existingKakao = js.context['Kakao'];
    if (existingKakao != null) {
      return Future.value();
    }

    final existingScript = html.document.getElementById(_sdkElementId);
    if (existingScript != null) {
      return _waitUntilLoaded();
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..id = _sdkElementId
      ..src = _sdkUrl
      ..async = true;

    script.onLoad.first.then((_) => completer.complete());
    script.onError.first.then((_) {
      completer.completeError(
        const KakaoLoginUnsupportedException(
          'Kakao JavaScript SDK를 불러오지 못했습니다.',
        ),
      );
    });

    html.document.head?.append(script);
    return completer.future;
  }

  Future<void> _waitUntilLoaded() async {
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (js.context['Kakao'] != null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    throw const KakaoLoginUnsupportedException(
      'Kakao JavaScript SDK 초기화 시간이 초과되었습니다.',
    );
  }

  void _initializeSdk() {
    final kakao = js.context['Kakao'] as js.JsObject?;
    if (kakao == null) {
      throw const KakaoLoginUnsupportedException(
        'Kakao JavaScript SDK가 준비되지 않았습니다.',
      );
    }

    final isInitialized = kakao.callMethod('isInitialized') as bool;
    if (!isInitialized) {
      kakao.callMethod('init', [AppEnvironment.kakaoJavaScriptKey]);
    }
  }

  Future<String> _loginWithPopup() {
    final kakao = js.context['Kakao'] as js.JsObject;
    final auth = kakao['Auth'] as js.JsObject;
    final completer = Completer<String>();

    auth.callMethod('login', [
      js.JsObject.jsify({
        'scope': _profileConsentScope,
        'success': js.JsFunction.withThis((_, Object authObject) {
          final tokenObject = authObject as js.JsObject;
          final accessToken = tokenObject['access_token'] as String? ?? '';
          if (accessToken.isEmpty) {
            completer.completeError(
              const KakaoLoginUnsupportedException(
                '카카오 access token을 가져오지 못했습니다.',
              ),
            );
            return;
          }

          completer.complete(accessToken);
        }),
        'fail': js.JsFunction.withThis((_, Object error) {
          completer.completeError(
            KakaoLoginUnsupportedException('카카오 로그인에 실패했습니다. $error'),
          );
        }),
      }),
    ]);

    return completer.future;
  }
}
