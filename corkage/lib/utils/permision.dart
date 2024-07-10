import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

Future<List<CameraDescription>> requestPermissions() async {
  PermissionStatus status = await Permission.camera.request();
  if (status.isGranted) {
    return await availableCameras();
  } else {
    throw Exception('Camera permission not granted');
  }
}
