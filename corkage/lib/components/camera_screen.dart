import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// 카메라 목록을 전달받기 위해 필요합니다.
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
        title: Text('카메라 미리보기'),
      ),
      body: CameraPreview(controller!), // 카메라 미리보기를 표시합니다.
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: '사진 촬영',
        child: Icon(Icons.camera_alt),
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
      // 여기에서 이미지와 함께 다른 화면으로 이동할 수 있습니다.
      print('사진 촬영 완료: ${image.path}');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: ${e.toString()}')),
      );
    }
  }
}
