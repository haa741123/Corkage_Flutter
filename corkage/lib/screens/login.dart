import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:camera/camera.dart';
import '/routes.dart';
import 'Index.dart';
import 'First.dart';

class Login extends StatefulWidget {
  final List<CameraDescription>? cameras;
  Login({Key? key, this.cameras}) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

const String REST_API_KEY = '6b5cc3ff382b0cb3ea15795729b3329f';
const String REDIRECT_URI = 'https://corkage.store/auth/kakao/callback';

class _LoginState extends State<Login> {
  late WebViewController _controller;
  @override
  void initState() {
    super.initState();
    _checkStoredUserInfo();
  }

  Future<void> _checkStoredUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');
    final nickname = prefs.getString('nickname');

    if (token != null && userId != null && nickname != null) {
      // User information exists, navigate to index page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/index');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20.0),
          Expanded(
            child: WebView(
              initialUrl: 'https://corkage.store/login',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
              },
              onPageFinished: (String url) {
                _controller.evaluateJavascript('''
                  if (typeof REST_API_KEY === 'undefined') {
                    const REST_API_KEY = '$REST_API_KEY';
                  }
                  if (typeof REDIRECT_URI === 'undefined') {
                    const REDIRECT_URI = '$REDIRECT_URI';
                  }
                  
                  if (document.getElementById('kakao-login-btn')) {
                    document.getElementById('kakao-login-btn').addEventListener('click', function() {
                      const KAKAO_AUTH_URL = `https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=${REST_API_KEY}&redirect_uri=${REDIRECT_URI}`;
                      window.location.href = KAKAO_AUTH_URL;
                    });
                  }
                ''');

                if (url
                    .startsWith('https://corkage.store/auth/kakao/callback')) {
                  _injectJavaScript();
                }
              },
              javascriptChannels: <JavascriptChannel>{
                JavascriptChannel(
                  name: 'saveLoginInfo',
                  onMessageReceived: (JavascriptMessage message) {
                    _saveLoginInfo(message.message);
                  },
                ),
              },
              gestureNavigationEnabled: true,
            ),
          ),
        ],
      ),
    );
  }

  void _injectJavaScript() {
    _controller.evaluateJavascript('''
    function checkLoginStatus() {
      var loginData = document.body.innerText;
      try {
        var jsonData = JSON.parse(loginData);
        if (jsonData.status === 'success') {
          saveLoginInfo.postMessage(JSON.stringify(jsonData));
        }
      } catch (e) {
        console.error('JSON 파싱 오류:', e);
        console.log('Raw data:', loginData);
      }
    }

    // 페이지 로드 완료 시 로그인 상태 확인
    checkLoginStatus();

    // 주기적으로 로그인 상태 확인 (옵션)
    setInterval(checkLoginStatus, 1000);
  ''');
  }

  void _saveLoginInfo(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', jsonData['token']);
      await prefs.setString('user_id', jsonData['user_id'].toString());
      await prefs.setString('nickname', jsonData['nickname']);
      print(
          'Login info saved: Token=${jsonData['token']}, UserId=${jsonData['user_id']}, Nickname=${jsonData['nickname']}');

      // 첫 실행 여부 확인
      bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

      if (isFirstRun) {
        // 첫 실행이면 First.dart로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FirstRunWebView(),
          ),
        );
      } else {
        // 첫 실행이 아니면 index 페이지로 이동
        Navigator.of(context).pushReplacementNamed('/index');
      }
    } catch (e) {
      print('Error saving login info: $e');
    }
  }
}
