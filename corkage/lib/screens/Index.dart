import 'package:flutter/material.dart';
import '/routes.dart';
import '/widgets/BottomNavigationBar.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IndexPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  IndexPage({Key? key, this.cameras}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Scaffold의 배경색을 하얀색으로 설정
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: WebView(
            initialUrl: 'https://corkage.store/main',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            gestureNavigationEnabled: true,
            backgroundColor: Colors.white, // WebView의 배경색을 하얀색으로 설정
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 0,
        cameras: widget.cameras,
        onItemTapped: (index) {
          if (index == 0) return;
          switch (index) {
            case 0:
              Navigator.pushNamed(context, Routes.home);
              break;
            case 1:
              Navigator.pushNamed(context, Routes.map);
              break;
            case 2:
              Navigator.pushNamed(
                context,
                Routes.camera,
                arguments: widget.cameras,
              );
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
