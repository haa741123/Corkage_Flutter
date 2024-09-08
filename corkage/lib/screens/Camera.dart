import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '/widgets/BottomNavigationBar.dart';
import '/routes.dart';
import 'Camera_Result.dart';
import 'MyPage.dart';
import 'Community.dart';
import 'Map.dart';

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
      title: 'Flutter WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    if (controller.value.isInitialized) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!controller.value.isInitialized) {
      print('Camera is not initialized.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final image = await controller.takePicture();
      setState(() {
        imageFile = image;
      });

      final extractedText = await _performOCR(image);

      if (mounted) {
        Navigator.of(context).pop();
      }

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
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<String> _performOCR(XFile image) async {
    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final url =
          'https://vision.googleapis.com/v1/images:annotate?key=YOUR_API_KEY';
      final request = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "TEXT_DETECTION"}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['responses'][0]['textAnnotations'][0]['description'];
      } else {
        return 'Unable to extract text.';
      }
    } catch (e) {
      return 'OCR error: $e';
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
                  painter: FramePainter(), // Add frame overlay
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

    double frameSize = size.width * 0.8; // Square frame size
    double left = (size.width - frameSize) / 2;
    double top = (size.height - frameSize) / 2;
    double cornerLength = 30.0; // Length of the corner lines

    // Top-left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Top-right corner
    canvas.drawLine(Offset(left + frameSize, top),
        Offset(left + frameSize - cornerLength, top), paint);
    canvas.drawLine(Offset(left + frameSize, top),
        Offset(left + frameSize, top + cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + frameSize),
        Offset(left + cornerLength, top + frameSize), paint);
    canvas.drawLine(Offset(left, top + frameSize),
        Offset(left, top + frameSize - cornerLength), paint);

    // Bottom-right corner
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
