import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> isCameraGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> isPhotosGranted() async {
    final photoStatus = await Permission.photos.status;
    if (photoStatus.isGranted || photoStatus.isLimited) return true;
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> isMicrophoneGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted || status.isLimited;
  }

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

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }
}
