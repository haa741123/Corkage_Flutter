import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'widgets/BottomNavigationBar.dart';
import 'routes.dart';
import 'screens/Camera.dart';
import 'screens/MyPage.dart';
import 'screens/Community.dart';
import 'utils/permision.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await requestPermissions();  // 권한 요청 및 사용 가능한 카메라 목록 대기
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
      initialRoute: Routes.home, // 초기 경로 설정
      routes: {
        Routes.home: (context) => HomePage(),
        Routes.camera: (context) => CameraApp(cameras: cameras),
        Routes.myPage: (context) => MyPage(),
        Routes.community: (context) => CommunityPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebViewController _controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      // 위치 정보를 로그에 출력
      print('Current position: ${position.latitude}, ${position.longitude}');

      // 위치 정보를 웹뷰로 전달
      _controller.runJavascript(
          "window.userPosition = {latitude: ${position.latitude}, longitude: ${position.longitude}};");
    }).catchError((e) {
      print('Error getting location: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(10.0), // AppBar의 높이를 50으로 설정
        child: AppBar(
        ),
      ),
      body: WebView(
        initialUrl: 'http://121.142.17.86:85/',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
          // 위치 정보를 웹뷰로 전달
          if (_currentPosition != null) {
            print('WebView created with position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
            _controller.runJavascript(
                "window.userPosition = {latitude: ${_currentPosition?.latitude}, longitude: ${_currentPosition?.longitude}};");
          }
        },
        onPageStarted: (String url) {
          print('Page started loading: $url');
        },
        onPageFinished: (String url) {
          print('Page finished loading: $url');
          // 위치 정보를 웹뷰로 전달
          if (_currentPosition != null) {
            print('Page finished loading with position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
            _controller.runJavascript(
                "window.userPosition = {latitude: ${_currentPosition?.latitude}, longitude: ${_currentPosition?.longitude}};");
          }
        },
        gestureNavigationEnabled: true,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
            case 1:
              Navigator.pushNamed(context, Routes.camera);
              break;
            case 2:
              Navigator.pushNamed(context, Routes.community);
              break;
            case 3:
              Navigator.pushNamed(context, Routes.myPage);
              break;
          }
        },
      ),
    );
  }
}
