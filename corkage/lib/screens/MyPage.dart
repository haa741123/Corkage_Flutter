import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:camera/camera.dart'; // camera 패키지 추가
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';

class MyPage extends StatefulWidget {
  final List<CameraDescription>? cameras; // cameras 매개변수 추가

  MyPage({Key? key, this.cameras}) : super(key: key); // 생성자 수정

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20.0),
          Expanded(
            child: Stack(
              children: [
                WebView(
                  initialUrl: 'https://corkage.store/mypage',
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controller = webViewController;
                  },
                  gestureNavigationEnabled: true,
                ),
                Positioned(
                  top: 30.0,
                  right: 16.0,
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Colors.black, size: 30.0),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.settings);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 3,
        cameras: widget.cameras, // cameras 매개변수 전달
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
            case 1:
              Navigator.pushNamed(context, Routes.map,
                  arguments: widget.cameras);
              break;
            case 2:
              Navigator.pushNamed(context, Routes.camera,
                  arguments: widget.cameras);
              break;

            case 3:
              Navigator.pushNamed(context, Routes.myPage,
                  arguments: widget.cameras);
              break;
          }
        },
      ),
    );
  }
}
