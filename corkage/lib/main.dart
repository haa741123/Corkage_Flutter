import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'widgets/BottomNavigationBar.dart';
import 'routes.dart';
import 'screens/Camera.dart';
import 'screens/MyPage.dart';
import 'screens/Community.dart';
import 'screens/SettingsPage.dart';
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
        Routes.settings: (context) => SettingsPage(),
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
    _checkFirstLaunch(); // 앱 첫 실행 여부 체크 및 광고 수신 동의 확인
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLaunch = prefs.getBool('isFirstLaunch');
    
    if (isFirstLaunch == null || isFirstLaunch) {
      // 첫 실행인 경우
      _showAdsConsentDialog();
      prefs.setBool('isFirstLaunch', false); // 첫 실행 이후로 설정
    }
  }

  void _showAdsConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자 동의 전 다이얼로그 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('광고 수신 동의'),
          content: Text('광고 수신을 허용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                _setAdsConsent(false);
                Navigator.of(context).pop();
              },
              child: Text('거부'),
            ),
            TextButton(
              onPressed: () {
                _setAdsConsent(true);
                Navigator.of(context).pop();
              },
              child: Text('허용'),
            ),
          ],
        );
      },
    );
  }

  void _setAdsConsent(bool isConsented) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('adsConsent', isConsented);

    String message;
    if (isConsented) {
      String currentTime = DateTime.now().toString();
      prefs.setString('adsConsentTime', currentTime);
      message = '광고 수신을 허용했습니다: $currentTime';
      print(message);
    } else {
      message = '광고 수신을 거부했습니다.';
      print(message);
    }

    // 하단 스낵바로 알림 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        child: AppBar(),
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
