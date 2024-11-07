import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/Map.dart';
import '/routes.dart';
import '/screens/Camera.dart';
import '/screens/MyPage.dart';
import '/screens/Index.dart';
import '/screens/SettingsPage.dart';
import '/screens/NoticePage.dart';
import '/screens/Login.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Ensure this import is present

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/index': (context) => IndexPage(cameras: cameras),
        Routes.home: (context) => IndexPage(cameras: cameras),
        Routes.camera: (context) =>
            cameras != null ? CameraApp(cameras: cameras!) : ErrorPage(),
        Routes.myPage: (context) => MyPage(cameras: cameras),
        Routes.map: (context) => MapPage(cameras: cameras),
        Routes.settings: (context) => SettingsPage(),
        Routes.notice: (context) => NoticePage(),
        Routes.login: (context) => Login(),
      },
    );
  }
}

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Error")),
      body: Center(
          child: Text("No cameras available. Please check device settings.")),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreenTimer();
  }

  Future<void> _startSplashScreenTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Future.delayed(Duration(seconds: 3), () {
      // Always navigate to home after splash screen
      Navigator.pushReplacementNamed(context, Routes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
