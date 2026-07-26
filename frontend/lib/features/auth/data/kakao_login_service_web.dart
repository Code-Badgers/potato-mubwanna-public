// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math';

import '../../../app/config/app_environment.dart';
import 'kakao_login_exception.dart';
import 'kakao_login_result.dart';

class KakaoLoginService {
  const KakaoLoginService();

  static const _sdkElementId = 'kakao-js-sdk';
  static const _sdkUrl =
      'https://t1.kakaocdn.net/kakao_js_sdk/2.8.1/kakao.min.js';
  static const _profileConsentScope = 'profile_nickname,account_email';
  static const _stateStorageKey = 'potato-kakao-oauth-state';
  static const _redirectUriStorageKey = 'potato-kakao-redirect-uri';

  Future<void> preload() async {
    if (AppEnvironment.kakaoJavaScriptKey.isEmpty) {
      return;
    }

    await _loadSdk();
    _initializeSdk();
  }

  Future<KakaoLoginResult> login() async {
    if (AppEnvironment.kakaoJavaScriptKey.isEmpty) {
      throw const KakaoLoginUnsupportedException(
        'KAKAO_JAVASCRIPT_KEY가 설정되지 않았습니다.',
      );
    }

    await _loadSdk();
    _initializeSdk();
    return _authorize();
  }

  KakaoAuthorizationCallback? readAuthorizationCallback() {
    final query = Uri.base.queryParameters;
    final authorizationCode = query['code'];
    final oauthError = query['error'];
    if (authorizationCode == null && oauthError == null) {
      return null;
    }

    final expectedState = html.window.sessionStorage[_stateStorageKey];
    final returnedState = query['state'];
    if (expectedState == null ||
        expectedState.isEmpty ||
        returnedState != expectedState) {
      throw const KakaoLoginUnsupportedException(
        '카카오 로그인 요청을 확인할 수 없습니다. 다시 시도해주세요.',
      );
    }
    if (oauthError != null) {
      throw const KakaoLoginUnsupportedException('카카오 로그인이 취소되었습니다.');
    }

    final redirectUri =
        html.window.sessionStorage[_redirectUriStorageKey] ?? '';
    if (authorizationCode == null ||
        authorizationCode.isEmpty ||
        redirectUri.isEmpty) {
      throw const KakaoLoginUnsupportedException(
        '카카오 로그인 응답이 올바르지 않습니다. 다시 시도해주세요.',
      );
    }

    return KakaoAuthorizationCallback(
      authorizationCode: authorizationCode,
      redirectUri: redirectUri,
    );
  }

  void clearAuthorizationCallback() {
    html.window.sessionStorage.remove(_stateStorageKey);
    html.window.sessionStorage.remove(_redirectUriStorageKey);
    if (Uri.base.queryParameters.containsKey('code') ||
        Uri.base.queryParameters.containsKey('error')) {
      html.window.history.replaceState(
        null,
        html.document.title,
        Uri.base.replace(query: '').toString(),
      );
    }
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

  KakaoLoginResult _authorize() {
    final kakao = js.context['Kakao'] as js.JsObject;
    final auth = kakao['Auth'] as js.JsObject;
    final state = _newState();
    final redirectUri = AppEnvironment.effectiveKakaoLoginRedirectUri;
    html.window.sessionStorage[_stateStorageKey] = state;
    html.window.sessionStorage[_redirectUriStorageKey] = redirectUri;

    auth.callMethod('authorize', [
      js.JsObject.jsify({
        'redirectUri': redirectUri,
        'scope': _profileConsentScope,
        'state': state,
      }),
    ]);
    return const KakaoAuthorizationRedirectResult();
  }

  String _newState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
