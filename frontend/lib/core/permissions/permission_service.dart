import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  bool get supportsRuntimePermissions => !kIsWeb;

  Future<PermissionStatus> locationStatus() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted || status.isLimited) {
      return status;
    }

    return _statusWithGeolocatorFallback(status);
  }

  Future<PermissionStatus> notificationStatus() {
    return Permission.notification.status;
  }

  Future<PermissionStatus> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted || status.isLimited) {
      return status;
    }

    return _statusWithGeolocatorFallback(status);
  }

  Future<PermissionStatus> requestNotification() {
    return Permission.notification.request();
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }

  Future<PermissionStatus> _statusWithGeolocatorFallback(
    PermissionStatus status,
  ) async {
    try {
      final geolocatorPermission = await Geolocator.checkPermission();
      if (geolocatorPermission == LocationPermission.always ||
          geolocatorPermission == LocationPermission.whileInUse) {
        return PermissionStatus.granted;
      }
    } catch (_) {
      return status;
    }

    return status;
  }
}
