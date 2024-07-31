import 'package:flutter/material.dart';

class NoticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("공지사항"),
      ),
      body: Center(
        child: Text("공지사항 내용이 여기에 표시됩니다."),
      ),
    );
  }
}
