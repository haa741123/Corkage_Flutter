import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/routes.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20.0), // 웹뷰 상단에 여백 추가
          Expanded(
            child: Stack(
              children: [
                WebView(
                  initialUrl: 'https://corkage.store/login', // 로그인 페이지 URL로 변경
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controller = webViewController;
                  },
                  gestureNavigationEnabled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
