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
import 'package:url_launcher/url_launcher.dart'; // URL 런처 패키지 추가

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
        Routes.home: (context) => IndexPage(cameras: cameras),
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
        return AlertDialog(
          title: Text('광고 수신 동의'),
          content: Text('광고 수신을 허용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _setAdsConsent(false);
              },
              child: Text('거부'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
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

  Future<void> _launchURL(String url) async {
    if (url.startsWith('tel:')) {
      await _makePhoneCall(url.substring(4)); // 'tel:' 제거
    } else if (url.startsWith('kakaomap://')) {
      await _openKakaoMap(url);
    } else {
      await _launchGenericUrl(url);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll('-', ''),
    );
    try {
      if (!await launchUrl(launchUri)) {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      print('Error launching phone call: $e');
    }
  }

  Future<void> _openKakaoMap(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) {
        // 카카오맵 앱이 설치되어 있지 않은 경우, 웹 버전 카카오맵으로 리다이렉트
        final webUrl = 'https://map.kakao.com/';
        if (!await launchUrl(Uri.parse(webUrl),
            mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $webUrl';
        }
      }
    } catch (e) {
      print('Error launching KakaoMap: $e');
    }
  }

  Future<void> _launchGenericUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
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
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith('intent:') ||
              request.url.startsWith('kakaomap://') ||
              request.url.startsWith('tel:')) {
            _launchURL(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
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
