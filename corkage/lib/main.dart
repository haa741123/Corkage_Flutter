import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'components/dialog.dart'; // dialog.dart 파일을 임포트합니다.
import 'components/bottom_navigation.dart'; // bottom_navigation.dart 파일을 임포트합니다.
import 'pages/camera_screen.dart'; // 카메라 화면 파일을 임포트합니다.
import 'package:camera/camera.dart'; // 카메라 패키지 임포트
import 'pages/photo_preview_screen.dart'; // 사진 미리보기 화면 파일을 임포트합니다.

// 'cameras'를 늦은 변수로 선언하여 사용 전에 초기화되도록 합니다.
late List<CameraDescription> cameras;

Future<void> main() async {
  // 모든 위젯이 제대로 바인딩되었는지 확인하고 카메라 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // 사용 가능한 카메라 목록을 초기화합니다.
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView and Camera Demo',
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
    if (index == 1) { // 카메라 버튼의 인덱스가 1이라고 가정합니다.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(cameras: cameras),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index; // 선택된 인덱스를 업데이트합니다.
      });
    }
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
            Placeholder(child: Text('여기에 두 번째 탭의 내용을 추가하세요.')),
            Placeholder(child: Text('여기에 세 번째 탭의 내용을 추가하세요.')),
            Placeholder(child: Text('여기에 네 번째 탭의 내용을 추가하세요.')),
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
