final sessionStartupRouteGate = SessionStartupRouteGate();

class SessionStartupRouteGate {
  bool _hasCompletedSessionStartup = false;
  String? _pendingLocation;

  String? redirectBeforeSessionStartup(String location) {
    if (_hasCompletedSessionStartup || _isStartupLocation(location)) {
      return null;
    }

    _pendingLocation = _safeLocalLocation(location);
    return '/startup';
  }

  String completeSessionStartup({
    required String fallbackRoute,
    required bool isAuthenticated,
  }) {
    _hasCompletedSessionStartup = true;
    final pendingLocation = _pendingLocation;
    _pendingLocation = null;

    if (isAuthenticated && pendingLocation != null) {
      return pendingLocation;
    }
    return fallbackRoute;
  }

  bool _isStartupLocation(String location) {
    return Uri.tryParse(location)?.path == '/startup';
  }

  String? _safeLocalLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !uri.path.startsWith('/') ||
        !_isAuthenticatedDestination(uri.path)) {
      return null;
    }
    return uri.toString();
  }

  bool _isAuthenticatedDestination(String path) {
    if (path == '/coupons' ||
        path == '/travel-records' ||
        path == '/settings' ||
        path == '/main' ||
        path.startsWith('/main/')) {
      return true;
    }

    final segments = Uri(path: path).pathSegments;
    return segments.length == 2 &&
        segments.first == 'spots' &&
        (int.tryParse(segments.last) ?? 0) > 0;
  }
}
