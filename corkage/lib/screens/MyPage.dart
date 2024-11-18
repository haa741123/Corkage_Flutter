import 'dart:convert';
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
  String _currentUrl = 'https://corkage.store/mypage';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('nickname') ?? '사용자';
    });
  }

  void _injectUsername() {
    if (_username != null) {
      _controller.evaluateJavascript('''
        (function() {
          const userInfoSection = document.querySelector('section.user-info h2');
          if (userInfoSection) {
            userInfoSection.innerText = '$_username님  >';
            userInfoSection.addEventListener('click', function() {
               location.href='/ch_name/$_username님'
            });
          }
        })();
      ''');
    }
  }

  void _injectMessageListener() {
    _controller.evaluateJavascript('''
      (function() {
        if (window.messageListenerInjected) return;
        window.messageListenerInjected = true;
        
        console.log("Injecting message listener");

        const originalConsoleLog = console.log;
        console.log = function() {
          originalConsoleLog.apply(console, arguments);
          const message = Array.from(arguments).join(' ');
          if (message.includes('"status":"success"')) {
            try {
              const data = JSON.parse(message);
              if (data.status === "success" && data.nickname) {
                window.FlutterWebView.postMessage(JSON.stringify({
                  type: 'updateNickname',
                  nickname: data.nickname
                }));
              }
            } catch (e) {
              console.error("Error parsing JSON:", e);
            }
          }
        };
      })();
    ''');
  }

  void _injectBookmarkTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('nickname') ?? '사용자';
    _controller.evaluateJavascript('''
    (function() {
      const collectionTitle = document.getElementById('collection-title');
      if (collectionTitle) {
        // 기존 count span 요소를 저장
        const countSpan = collectionTitle.querySelector('span.count');
        // 새로운 텍스트 내용 설정
        collectionTitle.textContent = '$nickname님의 컬렉션';
        // count span 요소가 있었다면 다시 추가
        if (countSpan) {
          collectionTitle.appendChild(countSpan);
        }
      }
    })();
  ''');
  }

  Future<void> _updateNickname(String newNickname) async {
    print("Updating nickname to: $newNickname");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', newNickname);
    setState(() {
      _username = newNickname;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('닉네임이 성공적으로 변경되었습니다: $newNickname')),
    );
    await _controller.loadUrl('https://corkage.store/mypage');
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
                  onPageFinished: (String url) {
                    setState(() {
                      _currentUrl = url;
                    });
                    _injectUsername();
                    if (url.contains('corkage.store/ch_name')) {
                      _injectMessageListener();
                    }
                    if (url == 'https://corkage.store/bookmark') {
                      _injectBookmarkTitle();
                    }
                  },
                  javascriptChannels: {
                    JavascriptChannel(
                      name: 'FlutterWebView',
                      onMessageReceived: (JavascriptMessage message) {
                        print("Received message from JS: ${message.message}");
                        try {
                          final data = jsonDecode(message.message);
                          if (data['type'] == 'updateNickname') {
                            _updateNickname(data['nickname']);
                          }
                        } catch (e) {
                          print("Error processing message: $e");
                        }
                      },
                    ),
                  },
                  gestureNavigationEnabled: true,
                ),
                if (_currentUrl == 'https://corkage.store/mypage')
                  Positioned(
                    top: 7.0,
                    right: 16.0,
                    child: IconButton(
                      icon:
                          Icon(Icons.settings, color: Colors.black, size: 25.0),
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
