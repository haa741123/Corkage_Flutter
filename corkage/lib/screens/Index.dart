import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IndexPage extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final String token;
  final String userId;

  const IndexPage({
    Key? key,
    this.cameras,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  WebViewController? _controller;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _logLoginStatus();
  }

  void _logLoginStatus() {
    print('로그인 상태: 토큰 = ${widget.token}, 사용자 ID = ${widget.userId}');
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
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              _setCookies(webViewController);
              _addAuthorizationHeader(webViewController);
            },
            javascriptChannels: <JavascriptChannel>{
              JavascriptChannel(
                name: 'CookieHandler',
                onMessageReceived: (JavascriptMessage message) {
                  print('Received message from JS: ${message.message}');
                },
              ),
            },
            initialCookies: [
              WebViewCookie(
                name: 'accessToken',
                value: widget.token,
                domain: '.corkage.store',
                path: '/',
              ),
              WebViewCookie(
                name: 'user_id',
                value: widget.userId,
                domain: '.corkage.store',
                path: '/',
              ),
            ],
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              // Handle the error, e.g. show an error message to the user
            },
            navigationDelegate: (NavigationRequest request) {
              _addAuthorizationHeader(_controller!);
              print('페이지 이동: ${request.url}');
              return NavigationDecision.navigate;
            },
            onPageStarted: (String url) {
              print('페이지 로딩 시작: $url');
            },
            onPageFinished: (String url) {
              print('페이지 로딩 완료: $url');
              _checkAndResetCookies(_controller!);
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
          if (index == 0) return;
          print('네비게이션 바 아이템 선택: $index');
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
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

  void _addAuthorizationHeader(WebViewController controller) {
    controller.runJavascript('''
      var originalFetch = window.fetch;
      window.fetch = function(url, options) {
        if (!options) {
          options = {};
        }
        if (!options.headers) {
          options.headers = {};
        }
        options.headers['Authorization'] = 'Bearer ${widget.token}';
        return originalFetch(url, options);
      };

      var originalXhrOpen = window.XMLHttpRequest.prototype.open;
      window.XMLHttpRequest.prototype.open = function() {
        var xhr = this;
        var args = Array.prototype.slice.call(arguments);
        var method = args[0];
        var url = args[1];
        var async = args[2];

        xhr.addEventListener('readystatechange', function() {
          if (xhr.readyState === 1) {
            xhr.setRequestHeader('Authorization', 'Bearer ${widget.token}');
          }
        });

        originalXhrOpen.apply(xhr, args);
      };
    ''');
  }

  void _setCookies(WebViewController controller) async {
    await controller.runJavascript('''
    function setCookie(name, value, days) {
      var expires = "";
      if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days*24*60*60*1000));
        expires = "; expires=" + date.toUTCString();
      }
      document.cookie = name + "=" + (value || "") + expires + "; path=/; domain=corkage.store; SameSite=Lax";
    }

    setCookie("accessToken", "${widget.token}", 30);
    setCookie("user_id", "${widget.userId}", 30);

    localStorage.setItem('accessToken', "${widget.token}");

    console.log('Cookies set:', document.cookie);
    console.log('localStorage set:', JSON.stringify(localStorage));
  ''');
  }

  void _checkAndResetCookies(WebViewController controller) async {
    await controller.runJavascript('''
      if (!document.cookie.includes('accessToken') || !document.cookie.includes('user_id')) {
        setCookie("accessToken", "${widget.token}", 30);
        setCookie("user_id", "${widget.userId}", 30);
        console.log('Cookies reset:', document.cookie);
        CookieHandler.postMessage('Cookies have been reset');
      } else {
        console.log('Cookies exist:', document.cookie);
        CookieHandler.postMessage('Cookies already exist');
      }
    ''');
  }
}
