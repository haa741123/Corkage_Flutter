import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'Camera_Result.dart';
import 'MyPage.dart';
import 'Community.dart';
import 'Map.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: cameras != null ? CameraApp(cameras: cameras!) : ErrorPage(),
      routes: {
        Routes.home: (context) => MapPage(cameras: cameras),
        Routes.camera: (context) =>
            cameras != null ? CameraApp(cameras: cameras!) : ErrorPage(),
        Routes.myPage: (context) => MyPage(cameras: cameras),
        Routes.community: (context) => CommunityPage(cameras: cameras),
      },
    );
  }
}

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Error")),
      body: Center(child: Text("Camera is not available")),
    );
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraApp({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraApp> createState() => CameraAppState();
}

class CameraAppState extends State<CameraApp> {
  late CameraController controller;
  String errorMessage = '';
  XFile? imageFile;
  String androidId = 'unknown';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getAndroidId();
  }

  Future<void> _getAndroidId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      androidId = androidInfo.id ?? 'unknown';
    });
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isNotEmpty) {
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
      );
      try {
        await controller.initialize();
        controller.setFlashMode(FlashMode.off);
        setState(() {});
      } catch (e) {
        setState(() {
          errorMessage = 'Error initializing camera: $e';
        });
      }
    } else {
      setState(() {
        errorMessage = 'No available cameras.';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future _takePicture() async {
    if (!controller.value.isInitialized) {
      print('Camera is not initialized.');
      return;
    }

    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('이미지 업로드 중...'),
                ],
              ),
            ),
          );
        },
      );

      final image = await controller.takePicture();
      setState(() {
        imageFile = image;
      });

      bool uploadSuccess = await _uploadImage(image.path);

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        if (uploadSuccess) {
          // 웹뷰 표시
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(),
                body: WebView(
                  initialUrl: 'https://corkage.store/drink_info',
                  javascriptMode: JavascriptMode.unrestricted,
                ),
              ),
            ),
          );
        } else {
          _showErrorMessage('이미지 업로드에 실패했습니다. 다시 시도해주세요.');
        }
      }
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showErrorMessage('사진 촬영에 실패했습니다: $e');
      }
    }
  }

  Future<bool> _uploadImage(String imagePath) async {
    try {
      final url = Uri.parse('https://corkage.store/api/v1/detect');
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath,
          filename: '$androidId.jpg'));
      print('업로드 요청 시작: $url');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('서버 응답 상태 코드: ${response.statusCode}');
      print('서버 응답 내용: $responseBody');
      if (response.statusCode == 200) {
        print('이미지 업로드 성공');
        return true;
      } else {
        print('이미지 업로드 실패: 상태 코드 ${response.statusCode}');
        print('응답 내용: $responseBody');
        _showErrorMessage('서버 오류: ${response.statusCode}. 나중에 다시 시도해주세요.');
        return false;
      }
    } catch (e, stackTrace) {
      print('이미지 업로드 중 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
      _showErrorMessage('네트워크 오류: $e');
      return false;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller.value.isInitialized) {
      final offset = details.localPosition;
      final double x = offset.dx / constraints.maxWidth;
      final double y = offset.dy / constraints.maxHeight;
      controller.setFocusPoint(Offset(x, y));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (!controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          CameraPreview(controller),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _onViewFinderTap(details, constraints),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: FramePainter(),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '와인 제품 전체가 다 보이도록\n정면으로 찍어주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.red,
                child: Icon(Icons.camera_alt, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 1,
        cameras: widget.cameras,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, Routes.home,
                  arguments: widget.cameras);
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraApp(cameras: widget.cameras),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacementNamed(context, Routes.community,
                  arguments: widget.cameras);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, Routes.myPage,
                  arguments: widget.cameras);
              break;
          }
        },
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    double frameSize = size.width * 0.8;
    double left = (size.width - frameSize) / 2;
    double top = (size.height - frameSize) / 2;
    double cornerLength = 30.0;
    // 프레임 모서리 그리기
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);
    canvas.drawLine(Offset(left + frameSize, top),
        Offset(left + frameSize - cornerLength, top), paint);
    canvas.drawLine(Offset(left + frameSize, top),
        Offset(left + frameSize, top + cornerLength), paint);
    canvas.drawLine(Offset(left, top + frameSize),
        Offset(left + cornerLength, top + frameSize), paint);
    canvas.drawLine(Offset(left, top + frameSize),
        Offset(left, top + frameSize - cornerLength), paint);
    canvas.drawLine(Offset(left + frameSize, top + frameSize),
        Offset(left + frameSize - cornerLength, top + frameSize), paint);
    canvas.drawLine(Offset(left + frameSize, top + frameSize),
        Offset(left + frameSize, top + frameSize - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
