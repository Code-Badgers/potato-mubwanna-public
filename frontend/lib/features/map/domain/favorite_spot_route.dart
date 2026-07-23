class FavoriteSpotRoute {
  const FavoriteSpotRoute({
    required this.routeName,
    required this.totalDistanceKm,
    required this.estimatedMinutes,
    required this.waypoints,
    required this.polyline,
  });

  factory FavoriteSpotRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteSpotRoute(
      routeName: json['routeName'] as String? ?? '나만의 감자 동선',
      totalDistanceKm: _readDouble(json['totalDistanceKm']),
      estimatedMinutes: _readInt(json['estimatedMinutes']),
      waypoints: _readList(json['waypoints'])
          .map(FavoriteSpotRouteWaypoint.fromJson)
          .toList(),
      polyline: _readList(json['polyline'])
          .map(FavoriteSpotRoutePoint.fromJson)
          .toList(),
    );
  }

  final String routeName;
  final double totalDistanceKm;
  final int estimatedMinutes;
  final List<FavoriteSpotRouteWaypoint> waypoints;
  final List<FavoriteSpotRoutePoint> polyline;

  bool get hasRoute => waypoints.length >= 2 && polyline.length >= 2;
}

class FavoriteSpotRouteWaypoint {
  const FavoriteSpotRouteWaypoint({
    required this.order,
    required this.spotId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceFromPreviousKm,
  });

  factory FavoriteSpotRouteWaypoint.fromJson(Map<String, dynamic> json) {
    return FavoriteSpotRouteWaypoint(
      order: _readInt(json['order']),
      spotId: json['spotId'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'POTATO_TOUR',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      distanceFromPreviousKm: _readDouble(json['distanceFromPreviousKm']),
    );
  }

  final int order;
  final String spotId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceFromPreviousKm;
}

class FavoriteSpotRoutePoint {
  const FavoriteSpotRoutePoint({
    required this.latitude,
    required this.longitude,
  });

  factory FavoriteSpotRoutePoint.fromJson(Map<String, dynamic> json) {
    return FavoriteSpotRoutePoint(
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
    );
  }

  final double latitude;
  final double longitude;
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<Map<String, dynamic>>().toList();
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
