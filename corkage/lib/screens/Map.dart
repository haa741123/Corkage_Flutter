import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'MyPage.dart';
import 'Index.dart';
import 'SettingsPage.dart';
import 'NoticePage.dart';
import '/utils/permision.dart';
import 'Camera.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapPage(cameras: cameras),
      routes: {
        Routes.home: (context) =>
            IndexPage(cameras: cameras, token: '', userId: ''),
        Routes.myPage: (context) => MyPage(cameras: cameras),
        Routes.map: (context) => MapPage(cameras: cameras),
        Routes.settings: (context) => SettingsPage(),
        Routes.notice: (context) => NoticePage(),
      },
    );
  }
}

class MapPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  MapPage({Key? key, this.cameras}) : super(key: key);

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
      builder: (BuildContext dialogContext) {
        // dialogContext 사용
        return AlertDialog(
          title: Text('광고 수신 동의'),
          content: Text('광고 수신을 허용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // dialogContext 사용
                _setAdsConsent(false);
              },
              child: Text('거부'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // dialogContext 사용
                _setAdsConsent(true);
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

    String message = isConsented
        ? '광고 수신을 허용했습니다: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'
        : '광고 수신을 거부했습니다.';

    // SnackBar 표시
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      // 사용자에게 설정에서 권한을 변경하도록 안내하는 메시지 표시
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
      print('Current position: ${position.latitude}, ${position.longitude}');
      _sendLocationToWebView(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      // 오류 발생 시 기본 위치 사용 또는 사용자에게 알림
    }
  }

  void _sendLocationToWebView(double latitude, double longitude) {
    if (_controller != null) {
      String jsCode =
          "if(typeof handleFlutterLocation === 'function') { handleFlutterLocation($latitude, $longitude); } else { console.error('handleFlutterLocation is not defined'); }";
      _controller.runJavascript(jsCode).then((_) {
        print('Location sent to WebView');
      }).catchError((error) {
        print('Error sending location to WebView: $error');
      });
    } else {
      print('WebView controller is not initialized');
    }
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
        selectedIndex: 1,
        cameras: widget.cameras,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;

            case 1:
              Navigator.pushNamed(context, Routes.map);
              break;

            case 2:
              if (widget.cameras != null && widget.cameras!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraApp(cameras: widget.cameras!),
                  ),
                );
              }
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
