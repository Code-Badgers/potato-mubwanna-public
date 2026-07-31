import 'package:url_launcher/url_launcher.dart';

import '../domain/map_spot.dart';

typedef MapUriLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalMapUri(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class KakaoMapNavigation {
  const KakaoMapNavigation._();

  static const maximumRouteSpots = 7;
  static const _baseUrl = 'https://map.kakao.com';

  static Uri destinationUri(MapSpot spot) {
    _validateCoordinates(spot);
    return Uri.parse('$_baseUrl/link/to/${_spotPath(spot)}');
  }

  static Uri routeUri(List<MapSpot> spots) {
    if (spots.length < 2) {
      throw ArgumentError.value(
        spots,
        'spots',
        'A route requires at least two spots.',
      );
    }

    final routeSpots = spots.take(maximumRouteSpots).toList(growable: false);
    for (final spot in routeSpots) {
      _validateCoordinates(spot);
    }
    final routePath = routeSpots.map(_spotPath).join('/');
    return Uri.parse('$_baseUrl/link/by/car/$routePath');
  }

  static String _spotPath(MapSpot spot) {
    final encodedName = Uri.encodeComponent(spot.name);
    return '$encodedName,${spot.latitude},${spot.longitude}';
  }

  static void _validateCoordinates(MapSpot spot) {
    final latitude = spot.latitude;
    final longitude = spot.longitude;
    final hasValidLatitude = latitude.isFinite && latitude.abs() <= 90;
    final hasValidLongitude = longitude.isFinite && longitude.abs() <= 180;
    if (!hasValidLatitude || !hasValidLongitude) {
      throw ArgumentError.value(
        '${spot.latitude},${spot.longitude}',
        'spot',
        'Map spot coordinates are invalid.',
      );
    }
  }
}
