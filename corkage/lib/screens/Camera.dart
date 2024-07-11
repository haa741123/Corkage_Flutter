import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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
  bool useFlash = false; // 플래시 사용 여부를 저장할 변수
  String extractedText = '';

  @override
  void initState() {
    super.initState();

    if (widget.cameras.isNotEmpty) {
      controller = CameraController(widget.cameras[0], ResolutionPreset.max, enableAudio: false);

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
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
      if (useFlash) {
        await controller.setFlashMode(FlashMode.torch); // 사진 찍기 전에 플래시 켜기
      } else {
        await controller.setFlashMode(FlashMode.off); // 플래시 끄기
      }
      final image = await controller.takePicture();
      setState(() {
        imageFile = image;
      });
      // 사진을 찍은 후 플래시 끄기
      await controller.setFlashMode(FlashMode.off);

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

  void _toggleFlash() {
    setState(() {
      useFlash = !useFlash;
    });
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
        title: Text('카메라'),
      ),
      body: imageFile == null
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: imageFile == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _toggleFlash,
                  child: Icon(
                    useFlash ? Icons.flash_on : Icons.flash_off,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _takePicture,
                  child: Icon(Icons.camera_alt),
                ),
              ],
            )
          : null,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(
    home: CameraApp(cameras: cameras),
  ));
}
