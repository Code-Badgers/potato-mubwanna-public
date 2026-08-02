// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';
import 'map_layout_waiter.dart';
import 'map_spot_selection_message.dart';

const _kakaoJavaScriptKey = String.fromEnvironment('KAKAO_JAVASCRIPT_KEY');

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({
    super.key,
    required this.spots,
    this.routePolyline = const [],
    this.onSpotSelected,
  });

  final List<MapSpot> spots;
  final List<FavoriteSpotRoutePoint> routePolyline;
  final ValueChanged<String>? onSpotSelected;

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  static Future<void>? _sdkLoadFuture;

  late final String _viewType;
  late final html.DivElement _mapElement;
  late final html.DivElement _messageElement;
  late final StreamSubscription<html.Event> _spotSelectedSubscription;

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

    _spotSelectedSubscription =
        html.window.on['potato-map-spot-selected-$_viewType'].listen((event) {
      final detail = (event as html.CustomEvent).detail;
      final message = _selectionMessageFromEventDetail(detail);
      final spotId = mapSpotIdFromSelectionMessage(message);
      if (spotId != null) {
        widget.onSpotSelected?.call(spotId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeMapAfterLayout());
    });
  }

  Object? _selectionMessageFromEventDetail(Object? detail) {
    if (detail == null || detail is String || detail is Map) {
      return detail;
    }

    try {
      final browserObject = js.JsObject.fromBrowserObject(detail);
      return <String, Object?>{'spotId': browserObject['spotId']};
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spots == widget.spots &&
        oldWidget.routePolyline == widget.routePolyline) {
      return;
    }
    _injectKakaoMapScript();
  }

  Future<void> _initializeMapAfterLayout() async {
    if (!mounted) {
      return;
    }

    if (_kakaoJavaScriptKey.isEmpty) {
      _showMessage('지도 설정이 완료되지 않았습니다. 앱 관리자에게 문의해주세요.');
      return;
    }

    // HtmlElementView는 첫 프레임 뒤에도 DOM 배치가 늦을 수 있어 실제 크기가 생길 때까지 기다린다.
    final hasLayout = await waitForMapLayout(
      hasLayout: () =>
          _mapElement.clientWidth > 0 && _mapElement.clientHeight > 0,
      shouldContinue: () => mounted,
    );
    if (!hasLayout) {
      if (!mounted) {
        return;
      }
      _showMessage('지도 화면을 준비하지 못했습니다. 페이지를 새로고침해주세요.');
      return;
    }

    try {
      await _loadKakaoSdk();
      await _waitForKakaoMaps();
      if (!mounted) {
        return;
      }

      _injectKakaoMapScript();
      _messageElement.style.display = 'none';
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        '카카오맵을 불러오지 못했습니다. 잠시 후 페이지를 새로고침해주세요.',
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

    final sdkSrc =
        'https://dapi.kakao.com/v2/maps/sdk.js?appkey=${Uri.encodeComponent(_kakaoJavaScriptKey)}&autoload=false';
    final existingScript = html.document.getElementById('kakao-map-sdk');
    if (existingScript != null) {
      final existingSrc = existingScript.getAttribute('src') ?? '';
      if (existingSrc == sdkSrc) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        return completer.future;
      }
      existingScript.remove();
    }

    final script = html.ScriptElement()
      ..id = 'kakao-map-sdk'
      ..type = 'text/javascript'
      ..async = true
      ..src = sdkSrc;

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

  static Future<void> _waitForKakaoMaps() async {
    for (var attempt = 0; attempt < 30; attempt += 1) {
      final hasKakaoMaps = _hasKakaoMaps();
      if (hasKakaoMaps) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    throw StateError('Kakao Maps SDK was loaded but kakao.maps is unavailable');
  }

  static bool _hasKakaoMaps() {
    final kakao = js.context['kakao'];
    if (kakao is! js.JsObject) {
      return false;
    }
    final maps = kakao['maps'];
    return maps != null;
  }

  void _injectKakaoMapScript() {
    final mapElementId = jsonEncode(_viewType);
    final spots = jsonEncode(widget.spots
        .map((spot) => {
              'name': spot.name,
              'id': spot.id,
              'lat': spot.latitude,
              'lng': spot.longitude,
              'rare': spot.isRare,
              'markerColor': spot.isRecommended
                  ? spot.markerColorHex
                  : spot.isRare
                      ? '#F6C23E'
                      : spot.markerColorHex,
            })
        .toList());
    final routePolyline = jsonEncode(widget.routePolyline
        .map((point) => {
              'lat': point.latitude,
              'lng': point.longitude,
            })
        .toList());

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
      const spots = $spots;
      const routePolyline = $routePolyline;
      if (mapElement.__potatoRenderSpots) {
        mapElement.__potatoRenderSpots(spots);
        if (mapElement.__potatoRenderRoutePolyline) {
          mapElement.__potatoRenderRoutePolyline(routePolyline);
        }
        return;
      }

      const firstSpot = spots.length > 0 ? spots[0] : null;
      const center = firstSpot
        ? new window.kakao.maps.LatLng(firstSpot.lat, firstSpot.lng)
        : new window.kakao.maps.LatLng(37.8228, 128.1555);
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

      let selectedMarkerElement = null;
      const markerElements = [];
      let markerOverlays = [];
      let routePolylineOverlay = null;

      function markerScale(level) {
        return Math.max(0.52, Math.min(0.88, 1.05 - ((level - 4) * 0.10)));
      }

      function applyMarkerScale() {
        const scale = markerScale(map.getLevel());
        markerElements.forEach(function (markerElement) {
          markerElement.style.transform = 'scale(' + scale + ')';
        });
      }

      function renderSpots(nextSpots) {
        markerOverlays.forEach(function (overlay) {
          overlay.setMap(null);
        });
        markerOverlays = [];
        markerElements.length = 0;
        selectedMarkerElement = null;

        nextSpots.forEach(function (spot) {
          const markerPosition = new window.kakao.maps.LatLng(spot.lat, spot.lng);
          const markerElement = document.createElement('button');
          markerElement.type = 'button';
          markerElement.title = spot.name;
          markerElement.setAttribute('aria-label', spot.name);
          markerElement.textContent = '🥔';
          markerElement.style.width = '36px';
          markerElement.style.height = '36px';
          markerElement.style.border = '2px solid ' + (spot.markerColor || '#F6C23E');
          markerElement.style.borderRadius = '999px';
          markerElement.style.background = '#FFFFFF';
          markerElement.style.boxShadow = '0 6px 14px rgba(0,0,0,0.16)';
          markerElement.style.fontSize = '18px';
          markerElement.style.lineHeight = '1';
          markerElement.style.cursor = 'pointer';
          markerElement.style.padding = '0';
          markerElement.style.transformOrigin = '50% 100%';
          markerElement.dataset.defaultBorderColor = spot.markerColor || '#F6C23E';
          markerElement.addEventListener('click', function () {
            if (selectedMarkerElement) {
              selectedMarkerElement.style.borderColor =
                selectedMarkerElement.dataset.defaultBorderColor || '#36D98F';
            }
            markerElement.style.borderColor = '#F6C23E';
            selectedMarkerElement = markerElement;
            window.dispatchEvent(new CustomEvent('potato-map-spot-selected-$mapElementId'.replace(/"/g, ''), {
              detail: { spotId: String(spot.id) }
            }));
          });
          markerElements.push(markerElement);

          const overlay = new window.kakao.maps.CustomOverlay({
            position: markerPosition,
            content: markerElement,
            xAnchor: 0.5,
            yAnchor: 1
          });
          overlay.setMap(map);
          markerOverlays.push(overlay);
        });
        applyMarkerScale();
      }

      function renderRoutePolyline(points) {
        if (routePolylineOverlay) {
          routePolylineOverlay.setMap(null);
          routePolylineOverlay = null;
        }
        if (!points || points.length < 2) {
          return;
        }
        routePolylineOverlay = new window.kakao.maps.Polyline({
          path: points.map(function (point) {
            return new window.kakao.maps.LatLng(point.lat, point.lng);
          }),
          strokeWeight: 5,
          strokeColor: '#F6C23E',
          strokeOpacity: 0.92,
          strokeStyle: 'solid'
        });
        routePolylineOverlay.setMap(map);
      }

      mapElement.__potatoRenderSpots = renderSpots;
      mapElement.__potatoRenderRoutePolyline = renderRoutePolyline;
      renderSpots(spots);
      renderRoutePolyline(routePolyline);

      window.kakao.maps.event.addListener(map, 'zoom_changed', applyMarkerScale);

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
  void dispose() {
    _spotSelectedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
