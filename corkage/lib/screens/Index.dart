import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // URL 런처 패키지 추가

class IndexPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  IndexPage({Key? key, this.cameras}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  late WebViewController _controller;
  final CookieManager _cookieManager = CookieManager();
  String? nickname;
  String? userId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WebView.platform = SurfaceAndroidWebView();
    _loadNickname();
  }

  // 닉네임과 사용자 ID 로드
  Future<void> _loadNickname() async {
    print('Starting to load nickname');
    final prefs = await SharedPreferences.getInstance();
    final loadedNickname = prefs.getString('nickname');
    final loadedUserId = prefs.getString('user_id');
    print('Loaded nickname: $loadedNickname, user_id: $loadedUserId');
    setState(() {
      nickname = loadedNickname;
      userId = loadedUserId;
    });
    print('Nickname set in state: $nickname');
    print('UserId set in state: $userId');
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print('Current location: ${position.latitude}, ${position.longitude}');
      _updateLocationInWebView(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // WebView에 위치 정보 업데이트
  void _updateLocationInWebView(double latitude, double longitude) {
    if (_controller != null) {
      _controller
          .evaluateJavascript('''
      if (typeof handleFlutterLocation === 'function') {
        handleFlutterLocation($latitude, $longitude);
      } else {
        console.log('handleFlutterLocation function not found');
      }
    ''')
          .then((result) => print('Location update result: $result'))
          .catchError((error) => print('Error updating location: $error'));
    } else {
      print('WebView controller is not initialized');
    }
  }

  // WebView에 닉네임 업데이트
  void _updateNickname() {
    print('Updating nickname in WebView');
    if (nickname != null) {
      _controller
          .evaluateJavascript('''
      var userGreeting = document.querySelector('.user-greeting strong');
      if (userGreeting) {
        userGreeting.innerHTML = '$nickname';
        console.log('Nickname updated to: $nickname');
      } else {
        console.log('User greeting element not found');
      }
    ''')
          .then((result) => print('JavaScript evaluation result: $result'))
          .catchError((error) => print('Error updating nickname: $error'));
    } else {
      print('Nickname is null, not updating WebView');
    }
  }

  // 사용자 쿠키 설정
  Future<void> _setUserCookies() async {
    if (userId != null && userId!.isNotEmpty) {
      try {
        await _cookieManager.setCookie(
          WebViewCookie(
            name: 'user_id',
            value: userId!,
            domain: 'corkage.store',
            path: '/',
          ),
        );
        print('User cookie set successfully - user_id: $userId');
      } catch (e) {
        print('Error setting user cookie: $e');
      }
    } else {
      print('UserId is null or empty, not setting cookie');
    }
  }

  // URL 처리 메서드
  Future<void> _launchURL(String url) async {
    if (url.startsWith('tel:')) {
      await _makePhoneCall(url.substring(4)); // 'tel:' 제거
    } else if (url.startsWith('kakaomap://')) {
      await _openKakaoMap(url);
    } else {
      await _launchGenericUrl(url);
    }
  }

  // 전화 걸기 메서드
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

  // 카카오맵 열기 메서드
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

  // 일반 URL 열기 메서드
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: WebView(
            initialUrl: 'https://corkage.store/main',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _controller = webViewController;
              await _setUserCookies();
              print('WebView controller created');
            },
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
              print('Current nickname: $nickname');
              _updateNickname();
              _getCurrentLocation();
            },
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith('tel:') ||
                  request.url.startsWith('kakaomap://') ||
                  request.url.startsWith('intent:')) {
                _launchURL(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            gestureNavigationEnabled: true,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 0,
        cameras: widget.cameras,
        onItemTapped: (index) {
          print('Bottom navigation item tapped: $index');
          if (index == 0) return;
          switch (index) {
            case 1:
              Navigator.pushNamed(context, Routes.map);
              break;
            case 2:
              Navigator.pushNamed(
                context,
                Routes.camera,
                arguments: widget.cameras,
              );
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
