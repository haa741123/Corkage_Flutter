import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'Camera.dart';
import 'MyPage.dart';
import 'Community.dart';
import 'SettingsPage.dart';
import 'NoticePage.dart';
import '/utils/permision.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

late List<CameraDescription> cameras;


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: Routes.home,  // 초기 경로 설정
      routes: {
        Routes.home: (context) => MapPage(),
        Routes.camera: (context) => CameraApp(cameras: cameras),
        Routes.myPage: (context) => MyPage(),
        Routes.community: (context) => CommunityPage(),
        Routes.settings: (context) => SettingsPage(),
        Routes.notice: (context) => NoticePage(),
      },
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late WebViewController _controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _getCurrentLocation();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLaunch = prefs.getBool('isFirstLaunch');

    if (isFirstLaunch == null || isFirstLaunch) {
      _showAdsConsentDialog();
      prefs.setBool('isFirstLaunch', false);
    }
  }

  void _showAdsConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
      String currentTime =
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      prefs.setString('adsConsentTime', currentTime);
      message = '광고 수신을 허용했습니다: $currentTime';
    } else {
      message = '광고 수신을 거부했습니다.';
    }

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
      print('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });

      print('Current position: ${position.latitude}, ${position.longitude}');

      if (_controller != null) {
        _sendLocationToWebView(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _sendLocationToWebView(double latitude, double longitude) {
    String jsCode =
        "window.handleFlutterLocation($latitude, $longitude);";
    _controller.runJavascript(jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://corkage.store',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;

          if (_currentPosition != null) {
            _sendLocationToWebView(
                _currentPosition!.latitude, _currentPosition!.longitude);
          }
        },
        onPageFinished: (String url) {
          if (_currentPosition != null) {
            _sendLocationToWebView(
                _currentPosition!.latitude, _currentPosition!.longitude);
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
