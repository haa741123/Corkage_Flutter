import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IndexPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  IndexPage({Key? key, this.cameras}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  late WebViewController _controller;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
  }

  Future<void> _sendTokenToServer() async {
    // 액세스 토큰과 유저 아이디를 Secure Storage에서 가져옴
    String? accessToken = await storage.read(key: 'accessToken');
    String? userId = await storage.read(key: 'user_id');

    if (accessToken != null && userId != null) {
      final url = Uri.parse('https://corkage.store/api/v1/set_flutter_token');
      var request = http.MultipartRequest('POST', url);
      request.fields['accessToken'] = accessToken;
      request.fields['user_id'] = userId;

      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          print('토큰 전송 성공');
          print(request.fields['accessToken']);
          print(request.fields['user_id']);
        } else {
          print('토큰 전송 실패: ${response.statusCode}');
        }
      } catch (e) {
        print('토큰 전송 중 에러 발생: $e');
      }
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
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (String url) async {
              if (url.contains('/main')) {
                // 페이지 로딩 완료 시 토큰 전송
                await _sendTokenToServer();
              }
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
