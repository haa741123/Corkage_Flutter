import 'package:flutter/material.dart';
import '/routes.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (int index) {
        onItemTapped(index); // 인덱스를 전달하여 외부에서 추가 작업을 수행할 수 있도록 함
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
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: '카메라',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '커뮤니티',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '마이 페이지',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.red, // 선택된 아이템 색상
      unselectedItemColor: Colors.black, // 선택되지 않은 아이템 색상
    );
  }
}
