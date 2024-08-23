import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/routes.dart';

class CameraResultPage extends StatefulWidget {
  final String imagePath;
  final String extractedText;

  const CameraResultPage({
    Key? key,
    required this.imagePath,
    required this.extractedText,
  }) : super(key: key);

  @override
  _CameraResultPageState createState() => _CameraResultPageState();
}

class _CameraResultPageState extends State<CameraResultPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebView(
            initialUrl: 'https://corkage.store/drink_info',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            gestureNavigationEnabled: true,
          ),
          Positioned(
            top: 40.0, // Positioning the back button below the status bar
            left: 16.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 30.0),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
