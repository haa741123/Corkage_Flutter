import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // AppBar의 높이를 50으로 설정
        child: AppBar(
          title: Text("마이 페이지"),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, Routes.settings);
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text("마이 페이지입니다")),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 3, // 적절한 인덱스로 설정
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
