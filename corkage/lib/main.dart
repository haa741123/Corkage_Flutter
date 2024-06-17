import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart'; // permission_handler 임포트
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

  // 위치 권한 요청 함수
  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        // 권한이 허용되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한 설정')),
        );
      } else {
        // 권한이 거부되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한 거부')),
        );
      }
    } else if (status.isGranted) {
      // 이미 권한이 허용된 경우
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 위치 권한을 승인했습니다')),
      );
    }
  }

  @override
  void dispose() {
    // context를 사용하지 않음
    // 클린업 작업 필요시 여기서 처리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('http://121.142.17.86/index'),
        ),
        initialOptions: InAppWebViewGroupOptions(
          android: AndroidInAppWebViewOptions(useHybridComposition: true),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => requestLocationPermission(),
        child: const Icon(Icons.location_on),
      ),
    );
  }
}
