import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> requestLocation() {
    return Permission.locationWhenInUse.request();
  }

  Future<PermissionStatus> requestNotification() {
    return Permission.notification.request();
  }
}

