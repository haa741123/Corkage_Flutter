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
      home: const MyHomePage(title: 'Flutter WebView Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(  // SafeArea 위젯으로 감싸서 상태바에 겹치지 않도록 함
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('http://121.142.17.86/index'),
          ),
          initialOptions: InAppWebViewGroupOptions(
            android: AndroidInAppWebViewOptions(useHybridComposition: true),
          ),
        ),
      ),
    );
  }
}
