import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dialog.dart'; // dialog.dart 파일을 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // 선택된 탭 인덱스

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 자동으로 다이얼로그 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 안전하게 context 사용
      if (mounted) {
        showBasicDialog(
          context,
          '모두의 잔은 위치 권한이 필요합니다',
          '확인 버튼을 누른 뒤 위치 권한을 허용해주세요',
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 선택된 인덱스 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('http://121.142.17.86/index'),
              ),
              initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(useHybridComposition: true),
              ),
            ),
            Container(
              color: Colors.green,
              child: const Center(
                child: Text('라벨 인식 화면', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
            Container(
              color: Colors.blue,
              child: const Center(
                child: Text('커뮤니티 화면', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
            Container(
              color: Colors.orange,
              child: const Center(
                child: Text('마이페이지 화면', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            label: '라벨 인식',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템 색상 설정
        type: BottomNavigationBarType.fixed, // 모든 아이템의 크기와 색상 고정
        onTap: _onItemTapped,
      ),
    );
  }
}
