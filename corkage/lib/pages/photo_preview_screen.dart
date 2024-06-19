import 'dart:io'; // File 클래스를 사용하기 위해 추가
import 'package:flutter/material.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사진 미리보기'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Image.file(
              File(imagePath), // File 클래스를 사용하여 이미지 파일을 읽습니다.
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, null); // 취소 버튼: 이전 화면으로 돌아갑니다.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // 취소 버튼의 배경색을 설정합니다.
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel),
                      Text('취소'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, imagePath); // 확인 버튼: 이미지 경로를 반환하며 이전 화면으로 돌아갑니다.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // 확인 버튼의 배경색을 설정합니다.
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle),
                      Text('확인'),
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
}
