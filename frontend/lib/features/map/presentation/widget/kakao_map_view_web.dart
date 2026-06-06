// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _kakaoJavaScriptKey = String.fromEnvironment('KAKAO_JAVASCRIPT_KEY');

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({super.key});

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  static Future<void>? _sdkLoadFuture;

  late final String _viewType;
  late final html.DivElement _mapElement;
  late final html.DivElement _messageElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'kakao-map-${DateTime.now().microsecondsSinceEpoch}';
    _mapElement = html.DivElement()
      ..id = _viewType
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.minWidth = '1px'
      ..style.minHeight = '1px'
      ..style.border = '0'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = '#EAF5D5';

    _messageElement = html.DivElement()
      ..style.position = 'absolute'
      ..style.left = '18px'
      ..style.right = '18px'
      ..style.top = '18px'
      ..style.padding = '12px 14px'
      ..style.borderRadius = '16px'
      ..style.backgroundColor = 'rgba(255,255,255,0.94)'
      ..style.boxShadow = '0 10px 24px rgba(0,0,0,0.08)'
      ..style.color = '#2B2B2B'
      ..style.fontSize = '13px'
      ..style.fontWeight = '700'
      ..style.lineHeight = '1.45'
      ..style.display = 'none';

    final wrapper = html.DivElement()
      ..style.position = 'relative'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.minWidth = '1px'
      ..style.minHeight = '1px'
      ..style.overflow = 'hidden'
      ..append(_mapElement)
      ..append(_messageElement);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => wrapper,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeMapAfterLayout());
    });
  }

  Future<void> _initializeMapAfterLayout() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }

    if (_kakaoJavaScriptKey.isEmpty) {
      _showMessage('KAKAO_JAVASCRIPT_KEY가 설정되지 않았습니다.');
      return;
    }

    if (_mapElement.clientWidth == 0 || _mapElement.clientHeight == 0) {
      _showMessage('지도 영역 크기를 계산하지 못했습니다.');
      return;
    }

    try {
      await _loadKakaoSdk();
      if (!mounted) {
        return;
      }

      final kakao = js_util.getProperty(html.window, 'kakao');
      final maps = js_util.getProperty(kakao, 'maps');
      final latLngConstructor = js_util.getProperty(maps, 'LatLng');
      final mapConstructor = js_util.getProperty(maps, 'Map');
      final markerConstructor = js_util.getProperty(maps, 'Marker');

      final center = js_util.callConstructor(latLngConstructor, [
        37.3808,
        128.6609,
      ]);
      final options = js_util.jsify({
        'center': center,
        'level': 9,
      });
      final map = js_util.callConstructor(mapConstructor, [
        _mapElement,
        options,
      ]);

      final markerPositions = [
        [37.3808, 128.6609],
        [37.7519, 128.8761],
        [37.3704, 128.3904],
        [38.2045, 128.5918],
      ];

      for (final position in markerPositions) {
        final markerPosition = js_util.callConstructor(latLngConstructor, [
          position[0],
          position[1],
        ]);
        final marker = js_util.callConstructor(markerConstructor, [
          js_util.jsify({'position': markerPosition}),
        ]);
        js_util.callMethod(marker, 'setMap', [map]);
      }

      js_util.callMethod(map, 'relayout', []);
      js_util.callMethod(map, 'setCenter', [center]);
      _messageElement.style.display = 'none';
    } catch (_) {
      _showMessage(
        '카카오맵을 불러오지 못했습니다. JavaScript 키, Kakao Map 사용 설정, Web 도메인 등록을 확인해주세요.',
      );
    }
  }

  static Future<void> _loadKakaoSdk() {
    final existingFuture = _sdkLoadFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final completer = Completer<void>();
    _sdkLoadFuture = completer.future;

    final existingScript = html.document.getElementById('kakao-map-sdk');
    if (existingScript != null) {
      _loadMaps(completer);
      return completer.future;
    }

    final script = html.ScriptElement()
      ..id = 'kakao-map-sdk'
      ..type = 'text/javascript'
      ..async = true
      ..src =
          'https://dapi.kakao.com/v2/maps/sdk.js?appkey=$_kakaoJavaScriptKey&autoload=false';

    script.onLoad.first.then((_) => _loadMaps(completer));
    script.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load Kakao Maps SDK'));
      }
    });

    html.document.head?.append(script);
    return completer.future;
  }

  static void _loadMaps(Completer<void> completer) {
    final kakao = js_util.getProperty(html.window, 'kakao');
    if (kakao == null) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Kakao SDK is unavailable'));
      }
      return;
    }

    final maps = js_util.getProperty(kakao, 'maps');
    js_util.callMethod(maps, 'load', [
      js.allowInterop(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }),
    ]);
  }

  void _showMessage(String message) {
    _messageElement
      ..text = message
      ..style.display = 'block';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
