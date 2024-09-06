import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/Map.dart';
import '/routes.dart';
import '/screens/Camera.dart';
import '/screens/MyPage.dart';
import '/screens/Community.dart';
import '/screens/SettingsPage.dart';
import '/screens/NoticePage.dart';
import '/utils/permision.dart';
import 'package:camera/camera.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  late List<CameraDescription> cameras;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CameraService().initializeCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/map': (context) => MapPage(),
        Routes.home: (context) => MapPage(),
        Routes.camera: (context) => CameraApp(cameras: CameraService().cameras),
        Routes.myPage: (context) => MyPage(),
        Routes.community: (context) => CommunityPage(),
        Routes.settings: (context) => SettingsPage(),
        Routes.notice: (context) => NoticePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreenTimer();
  }

  Future<void> _startSplashScreenTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    // 5초 동안 사진을 표시한 후 최초 실행 여부에 따라 페이지 이동
    Future.delayed(Duration(seconds: 3), () {
      if (isFirstRun) {
        prefs.setBool('isFirstRun', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 5초 동안 표시될 이미지
        child: Image.asset(
          'assets/spl.png', // 띄우고 싶은 이미지 경로
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage(
                imagePath: 'assets/onboarding1.png',
              ),
              _buildPage(
                imagePath: 'assets/onboarding2.png',
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: _currentPage == 1
                  ? TextButton(
                      onPressed: () {
                        print("Button pressed");
                        Navigator.pushNamed(context, '/map'); // 로그인 페이지로 이동
                      },
                      child: Text(
                        '카카오톡으로 3초 회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        '다음',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
  }) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
