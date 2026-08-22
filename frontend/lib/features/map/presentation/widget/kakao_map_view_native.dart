import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';
import 'map_spot_selection_message.dart';
import 'map_view_render_data.dart';

const _kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
const _nativeKakaoMapViewType = 'potato_mubwanna/kakao_map';

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({
    super.key,
    required this.spots,
    this.routePolyline = const [],
    this.routeSpotIds = const [],
    this.favoriteSpotIds = const {},
    this.currentLocation,
    this.onSpotSelected,
  });

  final List<MapSpot> spots;
  final List<FavoriteSpotRoutePoint> routePolyline;
  final List<String> routeSpotIds;
  final Set<String> favoriteSpotIds;
  final FavoriteSpotRoutePoint? currentLocation;
  final ValueChanged<String>? onSpotSelected;

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  MethodChannel? _channel;

  List<Map<String, Object>> get _spotPayload {
    final routeOrder = <String, int>{
      for (var index = 0; index < widget.routeSpotIds.length; index += 1)
        widget.routeSpotIds[index]: index + 1,
    };
    return widget.spots
        .map((spot) => {
              'id': spot.id,
              'name': spot.name,
              'latitude': spot.latitude,
              'longitude': spot.longitude,
              'favorite': widget.favoriteSpotIds.contains(spot.id),
              'routeIndex': routeOrder[spot.id] ?? 0,
              'markerColor': widget.favoriteSpotIds.contains(spot.id)
                  ? '#F6C23E'
                  : spot.markerColorHex,
            })
        .toList();
  }

  List<Map<String, Object>> get _routePolylinePayload => widget.routePolyline
      .map((point) => {
            'latitude': point.latitude,
            'longitude': point.longitude,
          })
      .toList();

  Map<String, Object>? get _currentLocationPayload {
    final location = widget.currentLocation;
    if (location == null) {
      return null;
    }
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }

  @override
  void didUpdateWidget(covariant KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final channel = _channel;
    if (channel != null) {
      if (!hasSameMapSpotRenderData(
            oldWidget.spots,
            oldWidget.favoriteSpotIds,
            widget.spots,
            widget.favoriteSpotIds,
          ) ||
          !hasSameRouteSpotIds(
            oldWidget.routeSpotIds,
            widget.routeSpotIds,
          )) {
        unawaited(channel.invokeMethod<void>('updateSpots', _spotPayload));
      }
      if (!hasSameRoutePolyline(
        oldWidget.routePolyline,
        widget.routePolyline,
      )) {
        unawaited(
          channel.invokeMethod<void>(
            'updateRoutePolyline',
            _routePolylinePayload,
          ),
        );
      }
      if (!hasSameMapPoint(
        oldWidget.currentLocation,
        widget.currentLocation,
      )) {
        unawaited(
          channel.invokeMethod<void>(
            'updateCurrentLocation',
            _currentLocationPayload,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_kakaoNativeAppKey.isEmpty ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return const _KakaoMapFallback();
    }

    final creationParams = <String, Object>{
      'nativeAppKey': _kakaoNativeAppKey,
      'latitude': widget.spots.isEmpty ? 37.8228 : widget.spots.first.latitude,
      'longitude':
          widget.spots.isEmpty ? 128.1555 : widget.spots.first.longitude,
      'zoomLevel': 9,
      'spots': _spotPayload,
      'routePolyline': _routePolylinePayload,
    };
    final currentLocation = _currentLocationPayload;
    if (currentLocation != null) {
      creationParams['currentLocation'] = currentLocation;
    }

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: _nativeKakaoMapViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    if (Platform.isIOS) {
      return UiKitView(
        viewType: _nativeKakaoMapViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return const _KakaoMapFallback();
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('potato_mubwanna/kakao_map_$id')
      ..setMethodCallHandler((call) async {
        if (call.method != 'spotSelected') {
          return;
        }
        final spotId = mapSpotIdFromSelectionMessage(call.arguments);
        if (spotId != null) {
          widget.onSpotSelected?.call(spotId);
        }
      });
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}

class _KakaoMapFallback extends StatelessWidget {
  const _KakaoMapFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEAF5D5),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '지도 설정이 완료되지 않아 지도를 표시할 수 없습니다.\n앱 관리자에게 문의해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4F6756),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
