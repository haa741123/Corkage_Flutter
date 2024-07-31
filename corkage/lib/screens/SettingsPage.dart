import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // 날짜 및 시간 포맷팅을 위한 패키지

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _adsAllowed = false;
  String _adsAllowedTime = ""; // 광고 수신 허용 시간

  @override
  void initState() {
    super.initState();
    _loadAdsConsentStatus();
  }

  Future<void> _loadAdsConsentStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _adsAllowed = prefs.getBool('adsConsent') ?? false;
      _adsAllowedTime = prefs.getString('adsConsentTime') ?? "";
    });
  }

  void _setAdsConsent(bool isConsented) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _adsAllowed = isConsented;
      if (isConsented) {
        _adsAllowedTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
        prefs.setString('adsConsentTime', _adsAllowedTime);
      } else {
        _adsAllowedTime = "";
      }
    });
    prefs.setBool('adsConsent', isConsented);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("설정"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("알림 설정"),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text("광고 수신 허용"),
            subtitle: _adsAllowed && _adsAllowedTime.isNotEmpty
                ? Text("$_adsAllowedTime에 광고 수신을 허용했습니다")
                : null,
            trailing: Switch(
              value: _adsAllowed,
              onChanged: (value) {
                _setAdsConsent(value);
              },
            ),
          ),
          ListTile(
            title: Text("공지사항"),
            onTap: () {
              // 공지사항 페이지로 이동하는 코드
            },
          ),
          ListTile(
            title: Text("앱 버전"),
            subtitle: Text("1.0.0"), // 실제 앱 버전을 표시
          ),
        ],
      ),
    );
  }
}
