import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showBasicDialog(BuildContext context, String title, String content) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기 후 위치 권한 요청
              requestLocationPermission(context); // 위치 권한 요청 함수 호출
            },
          ),
        ],
      );
    },
  );
}

Future<void> showCustomDialog(BuildContext context, String title, Widget content) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              content, // 사용자 정의 위젯
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기 후 위치 권한 요청
                  requestLocationPermission(context); // 위치 권한 요청 함수 호출
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 위치 권한 요청 함수
Future<void> requestLocationPermission(BuildContext context) async {
  var status = await Permission.location.status;
  if (status.isDenied) {
    // 위치 권한 요청
      if (await Permission.location.request().isGranted) {
        // 권한이 허용되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한 설정')),
        );
      } else {
        // 권한이 거부되었을 때
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한 거부')),
        );
      }
    } else if (status.isGranted) {
      // 이미 권한이 허용된 경우
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 위치 권한을 승인했습니다')),
      );
    }
}
