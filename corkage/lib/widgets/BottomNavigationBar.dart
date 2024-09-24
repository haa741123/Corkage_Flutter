import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

        Route? route;
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

        if (route != null) {
          Navigator.pushReplacement(context, route);
        }
      },
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            selectedIndex == 0
                ? 'assets/icons/Home_selected.svg'
                : 'assets/icons/Home.svg',
            width: 24,
            height: 24,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            selectedIndex == 1
                ? 'assets/icons/Location_selected.svg'
                : 'assets/icons/Location.svg',
            width: 24,
            height: 24,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            selectedIndex == 2
                ? 'assets/icons/Scan_selected.svg'
                : 'assets/icons/Scan.svg',
            width: 24,
            height: 24,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            selectedIndex == 3
                ? 'assets/icons/Profile_selected.svg'
                : 'assets/icons/Profile.svg',
            width: 24,
            height: 24,
          ),
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

  Route? _noAnimationRoute(String routeName) {
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
