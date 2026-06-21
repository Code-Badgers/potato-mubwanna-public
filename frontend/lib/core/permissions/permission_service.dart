import 'package:permission_handler/permission_handler.dart';

class PermissionService {
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
