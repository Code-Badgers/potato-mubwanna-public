import '../../domain/favorite_spot_route.dart';
import '../../domain/map_spot.dart';

bool hasSameMapSpotRenderData(
  List<MapSpot> previousSpots,
  Set<String> previousFavoriteSpotIds,
  List<MapSpot> nextSpots,
  Set<String> nextFavoriteSpotIds,
) {
  if (previousSpots.length != nextSpots.length) {
    return false;
  }

  for (var index = 0; index < previousSpots.length; index++) {
    final previous = previousSpots[index];
    final next = nextSpots[index];
    if (previous.id != next.id ||
        previous.name != next.name ||
        previous.latitude != next.latitude ||
        previous.longitude != next.longitude ||
        previous.markerColorHex != next.markerColorHex ||
        previousFavoriteSpotIds.contains(previous.id) !=
            nextFavoriteSpotIds.contains(next.id)) {
      return false;
    }
  }

  return true;
}

bool hasSameRoutePolyline(
  List<FavoriteSpotRoutePoint> previousPoints,
  List<FavoriteSpotRoutePoint> nextPoints,
) {
  if (previousPoints.length != nextPoints.length) {
    return false;
  }

  for (var index = 0; index < previousPoints.length; index++) {
    final previous = previousPoints[index];
    final next = nextPoints[index];
    if (previous.latitude != next.latitude ||
        previous.longitude != next.longitude) {
      return false;
    }
  }

  return true;
}

bool hasSameRouteSpotIds(
  List<String> previousRouteSpotIds,
  List<String> nextRouteSpotIds,
) {
  if (previousRouteSpotIds.length != nextRouteSpotIds.length) {
    return false;
  }

  for (var index = 0; index < previousRouteSpotIds.length; index++) {
    if (previousRouteSpotIds[index] != nextRouteSpotIds[index]) {
      return false;
    }
  }

  return true;
}

bool hasSameMapPoint(
  FavoriteSpotRoutePoint? previousPoint,
  FavoriteSpotRoutePoint? nextPoint,
) {
  if (previousPoint == null || nextPoint == null) {
    return previousPoint == nextPoint;
  }
  return previousPoint.latitude == nextPoint.latitude &&
      previousPoint.longitude == nextPoint.longitude;
}
