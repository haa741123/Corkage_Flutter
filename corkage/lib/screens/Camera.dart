import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'MyPage.dart';
import 'Community.dart';
import '/main.dart';

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
  String extractedText = '';

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
        // 플래시를 끕니다.
        controller.setFlashMode(FlashMode.off);
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          setState(() {
            errorMessage = '카메라 초기화 오류: ${e.code}';
          });
          switch (e.code) {
            case 'CameraAccessDenied':
              print("CameraController Error : CameraAccessDenied");
              break;
            default:
              print("CameraController Error");
              break;
          }
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
    try {
      final image = await controller.takePicture();
      setState(() {
        imageFile = image;
      });

      // OCR 처리
      await _performOCR(image);
    } catch (e) {
      print('사진 촬영 오류: $e');
    }
  }

  Future<void> _performOCR(XFile image) async {
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
        "language": "kor"
      };
      final header = {"apikey": "K85191029988957"};

      final response = await http.post(Uri.parse(url), body: payload, headers: header);

      // 응답 출력
      print('OCR API Response: ${response.body}');

      final result = jsonDecode(response.body);

      if (result['IsErroredOnProcessing'] == true) {
        throw Exception(result['ErrorMessage'].join(', '));
      }

      setState(() {
        extractedText = result['ParsedResults'][0]['ParsedText'] ?? '텍스트를 추출할 수 없습니다.';
      });
    } catch (e) {
      print('OCR 처리 오류: $e');
      setState(() {
        extractedText = 'OCR 처리 중 오류가 발생했습니다.';
      });
    }
  }

  void _confirmPicture() {
    // 여기에서 이미지를 서버로 전송하거나 저장하는 작업을 수행할 수 있습니다.
    print('사진 확인');
  }

  void _retakePicture() {
    setState(() {
      imageFile = null;
      extractedText = '';
    });
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
                      onTapDown: (details) => _onViewFinderTap(details, constraints),
                      child: CameraPreview(controller),
                    );
                  },
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Image.file(File(imageFile!.path)),
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(extractedText),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _confirmPicture,
                          child: Text('확인'),
                        ),
                        ElevatedButton(
                          onPressed: _retakePicture,
                          child: Text('취소'),
                        ),
                      ],
                    ),
                  ],
                ),
          CustomPaint(
            painter: FramePainter(),
            child: Container(),
          ),
          Positioned(
            bottom: 200,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '와인 제품 전체가 다 보이도록\n정면으로 찍어주세요',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
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

    final rect = Rect.fromLTWH(offsetX, offsetY, width, height); // 중앙에 위치한 프레임의 사각형
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(10)); // 둥근 모서리 사각형

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
      Routes.home: (context) => HomePage(),
      Routes.camera: (context) => CameraApp(cameras: cameras),
      Routes.myPage: (context) => MyPage(),
      Routes.community: (context) => CommunityPage(),
    },
  ));
}