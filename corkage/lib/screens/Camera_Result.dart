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
      backgroundColor: Colors.white, // Set background color to white
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 80.0), // Adding 80px space at the top
              Expanded(
                child: Container(
                  decoration: BoxDecoration(), // Ensuring no border or shadow
                  child: WebView(
                    initialUrl: 'https://corkage.store/drink_info',
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (WebViewController webViewController) {
                      _controller = webViewController;
                    },
                    gestureNavigationEnabled: true,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 30.0, // Adjusted for the 80px space
            left: 10.0,
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
