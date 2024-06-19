import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dialog.dart'; // dialog.dart 파일을 임포트합니다.
import 'bottom_navigation.dart'; // bottom_navigation.dart 파일이 존재하고 BottomNavigation 위젯을 포함하고 있는지 확인하세요.

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
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스입니다.

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 자동으로 대화 상자를 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showBasicDialog(
          context,
          '사용자의 위치 확인을 위해 권한이 필요합니다',
          '위치 권한을 승인해주세요',
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 선택된 인덱스를 업데이트합니다.
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
                url: WebUri('http://121.142.17.86/index'), // URL 사용을 위해 Uri.parse()를 적용합니다.
              ),
              initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(useHybridComposition: true),
              ),
            ),
            // 추가 탭을 위한 다른 위젯들을 여기에 추가하세요.
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
