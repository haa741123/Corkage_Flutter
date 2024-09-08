import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';

class CommunityPage extends StatelessWidget {
  final List<CameraDescription>? cameras;

  CommunityPage({Key? key, this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text("커뮤니티 페이지"),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Center(child: Text("커뮤니티 페이지입니다")),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 2,
        cameras: cameras, // 여기에 cameras 매개변수를 추가합니다
        onItemTapped: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
            case 1:
              Navigator.pushNamed(
                context,
                Routes.camera,
                arguments: cameras,
              );
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
