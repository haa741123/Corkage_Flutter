import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/routes.dart';
import '/screens/Community.dart';
import '/screens/MyPage.dart';
import '/screens/Camera.dart';
import '/screens/Map.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<CameraDescription>? cameras;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.cameras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (int index) {
        onItemTapped(index);

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
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.black,
      backgroundColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    );
  }

  Route _noAnimationRoute(String routeName) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          _getPage(routeName),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Widget _getPage(String routeName) {
    switch (routeName) {
      case Routes.home:
        return MapPage(cameras: cameras);
      case Routes.camera:
        return cameras != null && cameras!.isNotEmpty
            ? CameraApp(cameras: cameras!)
            : Center(child: Text('카메라를 사용할 수 없습니다.'));
      case Routes.community:
        return CommunityPage(cameras: cameras);
      case Routes.myPage:
        return MyPage(cameras: cameras);
      default:
        return MapPage(cameras: cameras);
    }
  }
}
