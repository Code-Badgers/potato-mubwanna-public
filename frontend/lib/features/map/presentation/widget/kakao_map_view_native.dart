import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/map_spot.dart';

const _kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
const _nativeKakaoMapViewType = 'potato_mubwanna/kakao_map';

class KakaoMapView extends StatefulWidget {
  const KakaoMapView({
    super.key,
    required this.spots,
    this.onSpotSelected,
  });

  final List<MapSpot> spots;
  final ValueChanged<String>? onSpotSelected;

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  MethodChannel? _channel;

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
      'spots': widget.spots
          .map((spot) => {
                'id': spot.id,
                'name': spot.name,
                'latitude': spot.latitude,
                'longitude': spot.longitude,
                'rare': spot.isRare,
                'markerColor': spot.isRare ? '#F6C23E' : spot.markerColorHex,
              })
          .toList(),
    };

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
        final spotId = call.arguments?.toString();
        if (spotId != null && spotId.isNotEmpty) {
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
            'KAKAO_NATIVE_APP_KEY 설정 후 모바일 카카오맵이 표시됩니다.',
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
