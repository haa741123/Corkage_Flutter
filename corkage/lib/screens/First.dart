import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '/routes.dart';

class FirstRunWebView extends StatefulWidget {
  final List<CameraDescription>? cameras;

  FirstRunWebView({Key? key, this.cameras}) : super(key: key);

  @override
  _FirstRunWebViewState createState() => _FirstRunWebViewState();
}

class _FirstRunWebViewState extends State<FirstRunWebView> {
  late WebViewController _controller;
  String? userId;

  @override
  void initState() {
    super.initState();
    if (WebView.platform is SurfaceAndroidWebView) {
      WebView.platform = SurfaceAndroidWebView();
    }
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
  }

  void _navigateToIndex() {
    Navigator.of(context)
        .pushReplacementNamed('/index', arguments: widget.cameras);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://corkage.store/taste_survey',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        onPageStarted: (String url) {
          if (userId != null) {
            _controller.evaluateJavascript('''
              document.cookie = "user_id=$userId; path=/";
            ''');
          }
        },
        onPageFinished: (String url) {
          _controller.evaluateJavascript('''
            // 기존의 alert 함수를 오버라이드
            var originalAlert = window.alert;
            window.alert = function(message) {
              originalAlert(message);
              // Flutter로 메시지 전송
              surveyComplete.postMessage(message);
            };
          ''');
        },
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
            name: 'surveyComplete',
            onMessageReceived: (JavascriptMessage message) {
              if (message.message == "저장되었습니다!") {
                _navigateToIndex();
              }
            },
          ),
        },
      ),
    );
  }
}
