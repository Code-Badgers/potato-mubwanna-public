import 'dart:ui' show PointMode;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/map/domain/map_spot.dart';
import 'package:potato_mubwanna/features/map/presentation/screen/map_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        mapSpotsProvider.overrideWith((ref) async => _spots),
        favoriteSpotControllerProvider.overrideWith(
          (ref) => FavoriteSpotController(
            MapSpotRepository(dio: Dio()),
            const LocalFavoriteSpotStorage(),
          )..state = const AsyncValue.data({'1', '2', '3'}),
        ),
        favoriteSpotRouteProvider.overrideWith((ref) async => _route),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MapScreen(
          hasMapConfiguration: true,
          mapViewBuilder: (spots, onSpotSelected) =>
              _PreviewMap(spots: spots, onSpotSelected: onSpotSelected),
        ),
      ),
    ),
  );
}

class _PreviewMap extends StatelessWidget {
  const _PreviewMap({required this.spots, required this.onSpotSelected});

  final List<MapSpot> spots;
  final ValueChanged<String> onSpotSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF4E8),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
          for (var index = 0; index < spots.length; index++)
            Positioned(
              left: 64 + (index * 105),
              top: 205 + ((index % 2) * 70),
              child: IconButton.filled(
                onPressed: () => onSpotSelected(spots[index].id),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF36D98F),
                  foregroundColor: Colors.white,
                ),
                tooltip: spots[index].name,
                icon: const Icon(Icons.location_on_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final routePaint = Paint()
      ..color = const Color(0xFFF6C23E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final points = [
      const Offset(80, 230),
      Offset(size.width * 0.45, 320),
      Offset(size.width - 70, 245),
    ];
    canvas.drawPoints(PointMode.polygon, points, roadPaint);
    canvas.drawPoints(PointMode.polygon, points, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _route = FavoriteSpotRoute(
  routeName: '정선 감자 하루 동선',
  totalDistanceKm: 12.3,
  estimatedMinutes: 30,
  waypoints: [
    FavoriteSpotRouteWaypoint(
      order: 1,
      spotId: '1',
      name: '정선 5일장',
      category: 'POTATO_MARKET',
      latitude: 37.38,
      longitude: 128.66,
      distanceFromPreviousKm: 0,
    ),
    FavoriteSpotRouteWaypoint(
      order: 2,
      spotId: '3',
      name: '감자 체험장',
      category: 'POTATO_EXPERIENCE',
      latitude: 37.40,
      longitude: 128.68,
      distanceFromPreviousKm: 6.1,
    ),
    FavoriteSpotRouteWaypoint(
      order: 3,
      spotId: '2',
      name: '감자 카페',
      category: 'POTATO_CAFE',
      latitude: 37.39,
      longitude: 128.67,
      distanceFromPreviousKm: 6.2,
    ),
  ],
  polyline: [
    FavoriteSpotRoutePoint(latitude: 37.38, longitude: 128.66),
    FavoriteSpotRoutePoint(latitude: 37.40, longitude: 128.68),
    FavoriteSpotRoutePoint(latitude: 37.39, longitude: 128.67),
  ],
);

const _spots = [
  MapSpot(
    id: '1',
    name: '정선 5일장',
    category: 'POTATO_MARKET',
    latitude: 37.38,
    longitude: 128.66,
    address: '강원 정선군',
    cityName: '정선',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
  MapSpot(
    id: '2',
    name: '감자 카페',
    category: 'POTATO_CAFE',
    latitude: 37.39,
    longitude: 128.67,
    address: '강원 정선군',
    cityName: '정선',
    congestionLevel: 'LOW',
    stampEnabled: true,
  ),
  MapSpot(
    id: '3',
    name: '감자 체험장',
    category: 'POTATO_EXPERIENCE',
    latitude: 37.40,
    longitude: 128.68,
    address: '강원 정선군',
    cityName: '정선',
    congestionLevel: 'NORMAL',
    stampEnabled: true,
  ),
];
