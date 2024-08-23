import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'Camera_Result.dart'; // Camera_Result 페이지를 가져옵니다
import 'MyPage.dart';
import 'Community.dart';
import 'Map.dart';

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraApp({super.key, required this.cameras});

  @override
  State<CameraApp> createState() => CameraAppState();
}

class CameraAppState extends State<CameraApp> {
  late CameraController controller;
  String errorMessage = '';
  XFile? imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
      );

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        controller.setFlashMode(FlashMode.off);
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          setState(() {
            errorMessage = '카메라 초기화 오류: ${e.code}';
          });
        }
      });
    } else {
      setState(() {
        errorMessage = '사용 가능한 카메라가 없습니다.';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!controller.value.isInitialized) {
      print('카메라가 초기화되지 않았습니다.');
      return;
    }

    try {
      // 로딩 화면을 띄웁니다.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 배경 이미지 추가
                Image.asset(
                  'assets/spl.png', // 배경 이미지 경로
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // 로딩 인디케이터와 텍스트 추가
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      '로딩 중입니다...', // 한글로 된 로딩 텍스트
                      style: TextStyle(
                        color: Colors.white, // 텍스트 색상 설정
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      // 사진 촬영
      final image = await controller.takePicture();
      setState(() {
        imageFile = image;
      });

      // OCR 수행
      final extractedText = await _performOCR(image);

      // 로딩 화면을 닫습니다.
      Navigator.of(context).pop();

      // OCR 결과와 이미지 경로, 카메라 리스트를 가지고 CameraResultPage로 이동합니다.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraResultPage(
            imagePath: image.path,
            extractedText: extractedText,
            cameras: widget.cameras, // 카메라 리스트 전달
          ),
        ),
      );
    } catch (e) {
      print('사진 촬영 오류: $e');
      Navigator.of(context).pop(); // 에러 발생 시 로딩 화면을 닫습니다.
    }
  }

  Future<String> _performOCR(XFile image) async {
    try {
      final bytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('이미지 디코딩 실패');
      }

      final resizedImage = img.copyResize(decodedImage, width: 1024);
      final resizedBytes = img.encodeJpg(resizedImage, quality: 70);

      final img64 = base64Encode(resizedBytes);

      final url = 'https://api.ocr.space/parse/image';
      final payload = {
        "base64Image": "data:image/jpg;base64,$img64",
        "language": "eng"
      };
      final header = {"apikey": "K85191029988957"};

      final response =
          await http.post(Uri.parse(url), body: payload, headers: header);

      print('OCR API Response: ${response.body}');

      final result = jsonDecode(response.body);

      if (result['IsErroredOnProcessing'] == true) {
        throw Exception(result['ErrorMessage'].join(', '));
      }

      return result['ParsedResults'][0]['ParsedText'] ?? '텍스트를 추출할 수 없습니다.';
    } catch (e) {
      print('OCR 처리 오류: $e');
      return 'OCR 처리 중 오류가 발생했습니다.';
    }
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
        automaticallyImplyLeading: false, // 뒤로 가기 아이콘을 삭제
      ),
      body: Stack(
        children: [
          imageFile == null
              ? LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _onViewFinderTap(details, constraints),
                      child: CameraPreview(controller),
                    );
                  },
                )
              : Container(), // 이미지가 찍히면 이 부분은 비워둡니다
          CustomPaint(
            painter: FramePainter(),
            child: Container(),
          ),
          // 화면 중앙에 텍스트 추가
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4, // 화면 중앙에 위치
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6), // 배경색을 흰색 반투명으로 설정
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '와인 제품 전체가 보이도록\n 정면으로 찍어주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black, // 텍스트 색상
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
                backgroundColor: Colors.red, // 버튼 색상 빨간색
                child: Icon(Icons.camera_alt, color: Colors.white), // 아이콘 색상 흰색
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

// 중앙 프레임을 그리는 CustomPainter 클래스
class FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white // 프레임 색상
      ..strokeWidth = 4 // 프레임 두께
      ..style = PaintingStyle.stroke;

    final double cornerSize = 30; // 코너의 길이
    final double cornerThickness = 4; // 코너의 두께
    final width = size.width * 0.8; // 프레임 너비
    final height = size.height * 0.5; // 프레임 높이
    final offsetX = (size.width - width) / 2; // 프레임을 중앙에 위치시키기 위한 X 오프셋
    final offsetY = (size.height - height) / 2; // 프레임을 중앙에 위치시키기 위한 Y 오프셋

    final rect =
        Rect.fromLTWH(offsetX, offsetY, width, height); // 중앙에 위치한 프레임의 사각형
    final RRect rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(10)); // 둥근 모서리 사각형

    // 좌측 상단 코너
    canvas.drawLine(
      Offset(rrect.left, rrect.top),
      Offset(rrect.left + cornerSize, rrect.top),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(rrect.left, rrect.top),
      Offset(rrect.left, rrect.top + cornerSize),
      paint..strokeWidth = cornerThickness,
    );

    // 우측 상단 코너
    canvas.drawLine(
      Offset(rrect.right, rrect.top),
      Offset(rrect.right - cornerSize, rrect.top),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(rrect.right, rrect.top),
      Offset(rrect.right, rrect.top + cornerSize),
      paint..strokeWidth = cornerThickness,
    );

    // 좌측 하단 코너
    canvas.drawLine(
      Offset(rrect.left, rrect.bottom),
      Offset(rrect.left + cornerSize, rrect.bottom),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(rrect.left, rrect.bottom),
      Offset(rrect.left, rrect.bottom - cornerSize),
      paint..strokeWidth = cornerThickness,
    );

    // 우측 하단 코너
    canvas.drawLine(
      Offset(rrect.right, rrect.bottom),
      Offset(rrect.right - cornerSize, rrect.bottom),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(rrect.right, rrect.bottom),
      Offset(rrect.right, rrect.bottom - cornerSize),
      paint..strokeWidth = cornerThickness,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(
    home: CameraApp(cameras: cameras),
    routes: {
      Routes.home: (context) => MapPage(),
      Routes.camera: (context) => CameraApp(cameras: cameras),
      Routes.myPage: (context) => MyPage(),
      Routes.community: (context) => CommunityPage(),
    },
  ));
}
