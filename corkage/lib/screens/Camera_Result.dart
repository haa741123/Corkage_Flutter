import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/routes.dart';
import 'camera.dart';
import 'package:camera/camera.dart';

class CameraResultPage extends StatefulWidget {
  final String imagePath;
  final String extractedText;
  final List<CameraDescription> cameras;

  const CameraResultPage({
    Key? key,
    required this.imagePath,
    required this.extractedText,
    required this.cameras,
  }) : super(key: key);

  @override
  _CameraResultPageState createState() => _CameraResultPageState();
}

class _CameraResultPageState extends State<CameraResultPage> {
  late WebViewController _controller;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBackToCamera();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 80.0),
                Expanded(
                  child: Stack(
                    children: [
                      WebView(
                        initialUrl:
                            'https://corkage.store/drink_info?search=${Uri.encodeComponent(widget.extractedText)}',
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated:
                            (WebViewController webViewController) {
                          _controller = webViewController;
                        },
                        onPageFinished: (String url) {
                          setState(() {
                            isLoading = false;
                          });
                        },
                        gestureNavigationEnabled: true,
                      ),
                      if (isLoading)
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 30.0,
              left: 10.0,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 30.0),
                onPressed: _navigateBackToCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateBackToCamera() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CameraApp(cameras: widget.cameras),
      ),
    );
  }
}
