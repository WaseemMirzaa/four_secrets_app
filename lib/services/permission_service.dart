import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) return true;
    
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    
    // For Android 13 and above, also check photos permission
    if (status.isPermanentlyDenied) {
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
    
    return false;
  }
}
