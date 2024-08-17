import 'package:flutter/material.dart';
import 'screens/Map.dart'; // MapPage 클래스를 포함하고 있는 파일

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FullScreenImagePage(),
      routes: {
        '/map': (context) => MapPage(), // MapPage를 위한 라우트 정의
      },
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 전체 화면을 차지하는 이미지
          Positioned.fill(
            child: Image.asset('assets/spl.png', // 자신의 이미지 경로로 수정하세요
              fit: BoxFit.cover, // 이미지를 화면에 꽉 차도록 설정
            ),
          ),
          // 하단에 위치한 버튼
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.5), // 반투명 배경
              padding: EdgeInsets.symmetric(vertical: 16.0), // 버튼의 높이 조절
              child: TextButton(
                onPressed: () {
                  // 버튼을 눌렀을 때 MapPage로 이동
                  print("Button pressed");
                  Navigator.pushNamed(context, '/map');
                },
                child: Text(
                  '카카오톡으로 3초 회원가입', // 버튼에 들어갈 텍스트
                  style: TextStyle(
                    color: Colors.white, // 텍스트 색상
                    fontSize: 20.0, // 텍스트 크기
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
