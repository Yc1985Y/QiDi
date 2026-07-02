import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted || storage.isLimited;
  }

  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }
}
