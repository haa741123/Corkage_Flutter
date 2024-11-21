import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '/routes.dart';

class FirstRunWebView extends StatefulWidget {
  final List<CameraDescription>? cameras;

  FirstRunWebView({Key? key, this.cameras}) : super(key: key);

  @override
  _FirstRunWebViewState createState() => _FirstRunWebViewState();
}

class _FirstRunWebViewState extends State<FirstRunWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (WebView.platform is SurfaceAndroidWebView) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://corkage.store/taste_survey',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
      ),
    );
  }
}
