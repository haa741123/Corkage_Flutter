import 'dart:io'; // 파일을 사용하기 위해 필요합니다.
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'photo_preview_screen.dart'; // 사진 미리보기 화면 파일을 임포트합니다.

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      // 첫 번째 사용 가능한 카메라로 컨트롤러를 초기화합니다.
      controller = CameraController(widget.cameras[0], ResolutionPreset.max);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    // 위젯의 상태가 파괴될 때 컨트롤러를 해제합니다.
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('라벨 스캔'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: CameraPreview(controller!), // 카메라 미리보기를 표시합니다.
          ),
          // 카메라 미리보기 아래에 버튼들을 배치합니다.
          Padding(
            padding: const EdgeInsets.all(60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _takePicture, // 사진 촬영 기능 연결
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt),
                      Text('촬영'),
                    ],
                  ),
                ),
                // 버튼 사이에 간격을 추가합니다.
                SizedBox(width: 20), // 버튼 사이에 20 픽셀의 간격을 추가합니다.
                ElevatedButton(
                  onPressed: _openGallery,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library),
                      Text('갤러리'),
                    ],
                  ),
                ),
                // 버튼 사이에 간격을 추가합니다.
                SizedBox(width: 20), // 버튼 사이에 20 픽셀의 간격을 추가합니다.
                ElevatedButton(
                  onPressed: _openSettings,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings),
                      Text('설정'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _takePicture() async {
    if (!controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: 카메라를 먼저 선택하세요.')),
      );
      return;
    }
    try {
      // 사진 촬영을 시도하고 파일 위치를 얻습니다.
      final image = await controller!.takePicture();
      // 사진 촬영 후 사진 미리보기 화면으로 이동합니다.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(imagePath: image.path),
        ),
      );
      print('사진 촬영 완료: ${image.path}');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: ${e.toString()}')),
      );
    }
  }

  void _openGallery() {
    // 갤러리 열기 기능 구현
    print('갤러리 열기');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('갤러리 열기 기능을 여기에 추가하세요.')),
    );
  }

  void _openSettings() {
    // 설정 열기 기능 구현
    print('설정 열기');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('설정 열기 기능을 여기에 추가하세요.')),
    );
  }
}
