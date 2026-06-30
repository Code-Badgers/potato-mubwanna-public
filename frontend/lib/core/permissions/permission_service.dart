import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  bool get supportsRuntimePermissions => !kIsWeb;

  Future<PermissionStatus> locationStatus() {
    return Permission.locationWhenInUse.status;
  }

  Future<PermissionStatus> notificationStatus() {
    return Permission.notification.status;
  }

  Future<PermissionStatus> requestLocation() {
    return Permission.locationWhenInUse.request();
  }

  Future<PermissionStatus> requestNotification() {
    return Permission.notification.request();
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }
}
