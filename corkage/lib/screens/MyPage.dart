import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';

class MyPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  MyPage({Key? key, this.cameras}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late WebViewController _controller;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('nickname') ??
          '사용자'; // Changed 'username' to 'nickname'
         
    });
  }

  void _injectUsername() {
    if (_username != null) {
      _controller.evaluateJavascript('''
        (function() {
          const userInfoSection = document.querySelector('section.user-info h2');
          if (userInfoSection) {
            // SharedPreferences에서 닉네임 가져오기
            userInfoSection.innerText = '$_username님  >';
            
            // 클릭 이벤트 (닉네임 변경 페이지로 이동)
            userInfoSection.addEventListener('click', function() {
               location.href='/ch_name/$_username님'
            });
          }
        })();
      ''');
    }
  }

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
                  onPageFinished: (_) {
                    _injectUsername();
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
        cameras: widget.cameras,
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
