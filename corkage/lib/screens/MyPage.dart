import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';

class MyPage extends StatefulWidget {
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
          SizedBox(height: 20.0),  // 웹뷰 상단에 40.0 높이의 여백 추가
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
                  top: 30.0,  // 아이콘의 상단 위치를 웹뷰 여백 이후 기준으로 설정
                  right: 16.0,
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Colors.black, size: 30.0), // 아이콘 크기를 30.0으로 조절
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
        selectedIndex: 3, // 적절한 인덱스로 설정
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
            case 1:
              Navigator.pushNamed(context, Routes.camera);
              break;
            case 2:
              Navigator.pushNamed(context, Routes.community);
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
