import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/map_spot.dart';

const _kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
const _nativeKakaoMapViewType = 'potato_mubwanna/kakao_map';

class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
    super.key,
    required this.spots,
  });

  final List<MapSpot> spots;

  @override
  Widget build(BuildContext context) {
    if (_kakaoNativeAppKey.isEmpty ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return const _KakaoMapFallback();
    }

    final creationParams = <String, Object>{
      'nativeAppKey': _kakaoNativeAppKey,
      'latitude': spots.isEmpty ? 37.8228 : spots.first.latitude,
      'longitude': spots.isEmpty ? 128.1555 : spots.first.longitude,
      'zoomLevel': 9,
      'spots': spots
          .map((spot) => {
                'id': spot.id,
                'name': spot.name,
                'latitude': spot.latitude,
                'longitude': spot.longitude,
                'rare': spot.isRare,
              })
          .toList(),
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: _nativeKakaoMapViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    }

    if (Platform.isIOS) {
      return UiKitView(
        viewType: _nativeKakaoMapViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    }

    return const _KakaoMapFallback();
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
