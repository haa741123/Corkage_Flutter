import 'package:flutter/material.dart';
import 'screens/Map.dart'; // MapPage 클래스를 포함하고 있는 파일
import '/routes.dart';
import '/screens/Camera.dart';
import '/screens/MyPage.dart';
import '/screens/Community.dart';
import '/screens/SettingsPage.dart';
import '/screens/NoticePage.dart';
import '/utils/permision.dart';
import 'package:camera/camera.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  late List<CameraDescription> cameras;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();  // 여기서 카메라 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FullScreenImagePage(),
        '/map': (context) => MapPage(),
        Routes.home: (context) => MapPage(),
        Routes.camera: (context) => CameraApp(cameras: CameraService().cameras),  // 초기화 후 접근
        Routes.myPage: (context) => MyPage(),
        Routes.community: (context) => CommunityPage(),
        Routes.settings: (context) => SettingsPage(),
        Routes.notice: (context) => NoticePage(),
      },
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/spl.png',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: TextButton(
                onPressed: () {
                  print("Button pressed");
                  Navigator.pushNamed(context, '/map');
                },
                child: Text(
                  '카카오톡으로 3초 회원가입',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
