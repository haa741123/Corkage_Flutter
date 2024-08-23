import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'Camera_Result.dart';
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
    if (controller.value.isInitialized) {
      controller.dispose();
    }
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
                  'assets/spl.png',
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
                      '라벨 분석중입니다',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        decoration: TextDecoration.none,
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
      if (mounted) {
        Navigator.of(context).pop();
      }

      // OCR 결과와 이미지 경로, 카메라 리스트를 가지고 CameraResultPage로 이동합니다.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraResultPage(
              imagePath: image.path,
              extractedText: extractedText,
              cameras: widget.cameras,
            ),
          ),
        );
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      if (mounted) {
        Navigator.of(context).pop(); // 에러 발생 시 로딩 화면을 닫습니다.
      }
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
                '와인 제품 전체가 보이도록\n정면으로 찍어주세요',
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

class FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerSize = 30;
    final double cornerThickness = 4;
    final width = size.width * 0.8;
    final height = size.height * 0.5;
    final offsetX = (size.width - width) / 2;
    final offsetY = (size.height - height) / 2;

    final rect = Rect.fromLTWH(offsetX, offsetY, width, height);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(10));

    // Draw corners
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
