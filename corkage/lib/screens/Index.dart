import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

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
