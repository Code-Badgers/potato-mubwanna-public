import 'package:flutter/material.dart';

import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';

class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
    super.key,
    required this.spots,
    this.routePolyline = const [],
    this.favoriteSpotIds = const {},
    this.currentLocation,
    this.onSpotSelected,
  });

  final List<MapSpot> spots;
  final List<FavoriteSpotRoutePoint> routePolyline;
  final Set<String> favoriteSpotIds;
  final FavoriteSpotRoutePoint? currentLocation;
  final ValueChanged<String>? onSpotSelected;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEAF5D5),
      child: Center(
        child: Text(
          '지도 설정이 완료되지 않아 지도를 표시할 수 없습니다.\n앱 관리자에게 문의해주세요.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
