// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
      ..dataset['kakaoMessage'] = 'true'
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
    ui_web.platformViewRegistry.registerViewFactory(
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

      _injectKakaoMapScript();
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
      if (!completer.isCompleted) {
        completer.complete();
      }
      return completer.future;
    }

    final script = html.ScriptElement()
      ..id = 'kakao-map-sdk'
      ..type = 'text/javascript'
      ..async = true
      ..src =
          'https://dapi.kakao.com/v2/maps/sdk.js?appkey=${Uri.encodeComponent(_kakaoJavaScriptKey)}&autoload=false';

    script.onLoad.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    script.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load Kakao Maps SDK'));
      }
    });

    html.document.head?.append(script);
    return completer.future;
  }

  void _injectKakaoMapScript() {
    final mapElementId = jsonEncode(_viewType);
    final spots = jsonEncode([
      {
        'name': '정선 5일장',
        'lat': 37.3808,
        'lng': 128.6609,
        'rare': true,
      },
      {
        'name': '강릉 커피거리',
        'lat': 37.7519,
        'lng': 128.8761,
        'rare': false,
      },
      {
        'name': '대관령 목장',
        'lat': 37.3704,
        'lng': 128.3904,
        'rare': true,
      },
      {
        'name': '속초 중앙시장',
        'lat': 38.2045,
        'lng': 128.5918,
        'rare': false,
      },
    ]);

    final script = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = '''
(function () {
  const mapElement = document.getElementById($mapElementId);
  const messageElement = mapElement && mapElement.parentElement
    ? mapElement.parentElement.querySelector('[data-kakao-message="true"]')
    : null;

  function showMessage(message) {
    if (!messageElement) return;
    messageElement.textContent = message;
    messageElement.style.display = 'block';
  }

  if (!mapElement || !window.kakao || !window.kakao.maps) {
    showMessage('카카오맵 SDK를 찾지 못했습니다.');
    return;
  }

  window.kakao.maps.load(function () {
    try {
      const center = new window.kakao.maps.LatLng(37.3808, 128.6609);
      const map = new window.kakao.maps.Map(mapElement, {
        center: center,
        level: 7,
        draggable: true,
        scrollwheel: true,
        disableDoubleClickZoom: false
      });

      map.setDraggable(true);
      map.setZoomable(true);
      map.addControl(
        new window.kakao.maps.ZoomControl(),
        window.kakao.maps.ControlPosition.RIGHT
      );

      const spots = $spots;
      spots.forEach(function (spot) {
        const markerPosition = new window.kakao.maps.LatLng(spot.lat, spot.lng);
        const markerElement = document.createElement('button');
        markerElement.type = 'button';
        markerElement.title = spot.name;
        markerElement.setAttribute('aria-label', spot.name);
        markerElement.textContent = spot.rare ? '🥔★' : '🥔';
        markerElement.style.width = spot.rare ? '58px' : '48px';
        markerElement.style.height = '48px';
        markerElement.style.border = '3px solid ' + (spot.rare ? '#F6C23E' : '#36D98F');
        markerElement.style.borderRadius = '999px';
        markerElement.style.background = '#FFFFFF';
        markerElement.style.boxShadow = '0 8px 18px rgba(0,0,0,0.18)';
        markerElement.style.fontSize = spot.rare ? '21px' : '24px';
        markerElement.style.lineHeight = '1';
        markerElement.style.cursor = 'pointer';
        markerElement.style.padding = '0';

        new window.kakao.maps.CustomOverlay({
          position: markerPosition,
          content: markerElement,
          xAnchor: 0.5,
          yAnchor: 1
        }).setMap(map);
      });

      map.relayout();
      map.setCenter(center);
      window.setTimeout(function () {
        map.relayout();
        map.setCenter(center);
      }, 100);

      mapElement.__potatoKakaoMap = map;
      if (messageElement) messageElement.style.display = 'none';
    } catch (error) {
      showMessage('카카오맵을 초기화하지 못했습니다.');
      console.error(error);
    }
  });
})();
''';

    html.document.body?.append(script);
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
