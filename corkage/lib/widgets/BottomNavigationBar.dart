import 'package:flutter/material.dart';
import '/routes.dart';
import '/screens/Community.dart';
import '/screens/MyPage.dart';
import '/screens/Camera.dart';
import '/main.dart';

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

        // 페이지 전환 애니메이션을 없앰
        Route route;
        switch (index) {
          case 0:
            route = _noAnimationRoute(Routes.home);
            break;
          case 1:
            route = _noAnimationRoute(Routes.camera);
            break;
          case 2:
            route = _noAnimationRoute(Routes.community);
            break;
          case 3:
            route = _noAnimationRoute(Routes.myPage);
            break;
          default:
            return;
        }

        Navigator.pushReplacement(context, route);
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: '', // 라벨을 빈 문자열로 설정하여 제거
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: '', // 라벨을 빈 문자열로 설정하여 제거
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '', // 라벨을 빈 문자열로 설정하여 제거
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '', // 라벨을 빈 문자열로 설정하여 제거
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.red, // 선택된 아이템 색상
      unselectedItemColor: Colors.black, // 선택되지 않은 아이템 색상
      showSelectedLabels: false, // 선택된 아이템의 라벨을 숨김
      showUnselectedLabels: false, // 선택되지 않은 아이템의 라벨을 숨김
      type: BottomNavigationBarType.fixed, // 높이가 변하지 않도록 설정
    );
  }

  Route _noAnimationRoute(String routeName) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => _getPage(routeName),
      transitionDuration: Duration.zero, // 전환 애니메이션 지속 시간을 0으로 설정
      reverseTransitionDuration: Duration.zero, // 뒤로 가기 애니메이션 지속 시간을 0으로 설정
    );
  }

  Widget _getPage(String routeName) {
    switch (routeName) {
      case Routes.home:
        return HomePage();
      case Routes.camera:
        return CameraPage();
      case Routes.community:
        return CommunityPage();
      case Routes.myPage:
        return MyPage();
      default:
        return HomePage();
    }
  }
}
