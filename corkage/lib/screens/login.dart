import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'index.dart';

class Login extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const Login({Key? key, this.cameras}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late WebViewController _controller;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _checkTokenAndNavigate();
    print('LoginState initialized');
  }

  Future<void> _checkTokenAndNavigate() async {
    print('Checking token and navigating');
    String? token = await storage.read(key: 'accessToken');
    String? userId = await storage.read(key: 'user_id');
    print('Stored token: $token, userId: $userId');
    if (token != null && userId != null) {
      if (await _validateToken(token)) {
        print('Token validated successfully');
        _navigateToIndex(token, userId);
      } else {
        print('Token validation failed');
        await _clearTokens();
      }
    }
  }

  Future<void> _clearTokens() async {
    print('Clearing tokens');
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'user_id');
  }

  Future<bool> _validateToken(String token) async {
    print('Validating token');
    try {
      final response = await http.get(
        Uri.parse('https://corkage.store/validate_token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Token validation response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('토큰 검증 중 오류 발생: $e');
      return false;
    }
  }

  void _navigateToIndex(String token, String userId) {
    print('Navigating to IndexPage with token: $token and userId: $userId');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => IndexPage(
          cameras: widget.cameras,
          token: token,
          userId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://corkage.store/login',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
            print('WebView created');
          },
          navigationDelegate: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            if (request.url
                .startsWith('https://corkage.store/auth/kakao/callback')) {
              Uri uri = Uri.parse(request.url);
              String? code = uri.queryParameters['code'];
              if (code != null) {
                _exchangeCodeForTokens(code);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          gestureNavigationEnabled: true,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  void _handleAuthComplete(String url) async {
    print('_handleAuthComplete called with URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['accessToken'];
        final userId = data['user_id'];

        print('Received accessToken: $accessToken, userId: $userId');

        if (accessToken != null && userId != null) {
          await storage.write(key: 'accessToken', value: accessToken);
          await storage.write(key: 'user_id', value: userId.toString());
          print('Token and userId stored in secure storage');

          _navigateToIndex(accessToken, userId.toString());
        } else {
          print('Failed to receive accessToken or userId');
        }
      } else {
        print('Failed to get token from server: ${response.statusCode}');
        print('Server response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching token from server: $e');
    }
  }

  Future<void> _exchangeCodeForTokens(String code) async {
    try {
      final response = await http.get(
        Uri.parse('https://corkage.store/auth/kakao/callback?code=$code'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['accessToken'];
        final userId = data['user_id'];

        if (accessToken != null && userId != null) {
          await storage.write(key: 'accessToken', value: accessToken);
          await storage.write(key: 'user_id', value: userId.toString());
          print('Token and userId stored in secure storage');

          _navigateToIndex(accessToken, userId.toString());
        } else {
          print('Failed to receive accessToken or userId');
          print('Server response: ${response.body}');
        }
      } else {
        print('Failed to exchange code for tokens: ${response.statusCode}');
        print('Server response: ${response.body}');
      }
    } catch (e) {
      print('Error exchanging code for tokens: $e');
    }
  }
}
