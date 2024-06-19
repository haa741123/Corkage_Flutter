import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // Platform 클래스를 사용하기 위해 추가

// 갤러리 접근 권한 요청을 위한 기본 다이얼로그 함수
Future<void> showGalleryPermissionDialog(BuildContext context, String title, String content, Function onGranted) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('취소'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
          ),
          TextButton(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기 후 갤러리 권한 요청
              requestGalleryPermission(context, onGranted); // 갤러리 권한 요청 함수 호출
            },
          ),
        ],
      );
    },
  );
}

// 갤러리 접근 권한 요청 함수
Future<void> requestGalleryPermission(BuildContext context, Function onGranted) async {
  var status = await Permission.photos.status; // 갤러리 권한 상태 확인 (iOS)
  
  // Android의 경우, storage 권한을 요청합니다.
  if (Platform.isAndroid) {
    status = await Permission.storage.status;
  }

  if (status.isDenied) {
    // 갤러리 또는 스토리지 권한 요청
    Permission permission = Platform.isIOS ? Permission.photos : Permission.storage;
    if (await permission.request().isGranted) {
      // 권한이 허용되었을 때
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('갤러리 접근 권한이 허용되었습니다.')),
      );
      onGranted(); // 권한이 허용된 후 콜백 실행
    } else {
      // 권한이 거부되었을 때
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('갤러리 접근 권한이 거부되었습니다.')),
      );
    }
  } else if (status.isGranted) {
    // 이미 권한이 허용된 경우
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미 갤러리 접근 권한이 허용되었습니다.')),
    );
    onGranted(); // 이미 권한이 허용된 경우에도 콜백 실행
  } else if (status.isRestricted || status.isPermanentlyDenied) {
    // 권한이 영구적으로 거부된 경우
    openAppSettings(); // 앱 설정으로 이동하도록 요청
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('갤러리 접근 권한을 설정에서 변경해주세요.')),
    );
  }
}
