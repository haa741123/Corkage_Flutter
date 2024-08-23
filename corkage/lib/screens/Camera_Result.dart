import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/routes.dart';
import 'camera.dart'; // CameraApp 페이지를 가져옵니다
import 'package:camera/camera.dart';

class CameraResultPage extends StatefulWidget {
  final String imagePath;
  final String extractedText;
  final List<CameraDescription> cameras; // 카메라 리스트 추가

  const CameraResultPage({
    Key? key,
    required this.imagePath,
    required this.extractedText,
    required this.cameras, // 카메라 리스트를 필수로 추가
  }) : super(key: key);

  @override
  _CameraResultPageState createState() => _CameraResultPageState();
}

class _CameraResultPageState extends State<CameraResultPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경 색상 흰색으로 설정
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 80.0), // 상단에 80px 여백 추가
              Expanded(
                child: Container(
                  decoration: BoxDecoration(), // 테두리나 그림자 제거
                  child: WebView(
                    initialUrl: 'https://corkage.store/drink_info',
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (WebViewController webViewController) {
                      _controller = webViewController;
                    },
                    onPageFinished: (String url) {
                      // 페이지가 로드된 후 JavaScript를 통해 추출된 텍스트 전달
                      _controller.evaluateJavascript(
                          "document.getElementById('searchField').value = '${widget.extractedText}';");
                    },
                    gestureNavigationEnabled: true,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 30.0, // 80px 여백에 맞춘 위치 조정
            left: 10.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 30.0),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CameraApp(cameras: widget.cameras), // 기존 카메라 리스트 전달
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
