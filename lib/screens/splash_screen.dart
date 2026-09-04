import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tablebid/screens/home_screen.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashOrMainScreenState createState() => _SplashOrMainScreenState();
}

class _SplashOrMainScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _isInFirebase = false;
  bool _isInDB = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
  try {
    final canContinue = await _checkAppVersion();

    if (!canContinue) {
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (!mounted) return;
      setState(() {
        _isInDB = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await UserApi().getUser(firebaseUser.uid);

      if (!mounted) return;
      setState(() {
        _isInDB = true;
        _isInFirebase = true;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      // supabase에 유저 없음
      if (!mounted) return;
      setState(() {
        _isInDB = false;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isInDB = false;
      _isLoading = false;
    });
  }
}

  // 버전 비교 함수
  bool _isUpdateRequired(String currentVersion, String minVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> min = minVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (current[i] < min[i]) return true; // 내 버전이 낮으면 업데이트 필수!
      if (current[i] > min[i]) return false;
    }
    return false; // 완벽히 같으면 통과
  }

  Future<bool> _checkAppVersion() async {
    try {
      // 내 폰에 깔린 앱 버전 가져오기 -> pubspec.yaml 읽음
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 파이어베이스에서 기준 가져오기
      DocumentSnapshot versionDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_version')
          .get();

      if (versionDoc.exists) {
        String minVersion = Platform.isIOS
            ? versionDoc.get('ios_min_version')
            : versionDoc.get('aos_min_version');

        print('>>>>>>>>>>> min version: ${minVersion}');

        String storeUrl = Platform.isIOS
            ? versionDoc.get('ios_url')
            : versionDoc.get(
                'aos_url',
              );

        // 내 버전이 허용치보다 낮으면
        if (_isUpdateRequired(currentVersion, minVersion)) {
          if(!mounted) return false;
          _showUpdateDialog(storeUrl);
          return false; // 스토어 url로 보냄
        }
      }
      return true;
    } catch (e) {
      // 오프라인이거나 에러가 났을 때는 일단 진입 허용 (또는 재시도 로직)
      print('>>>>>>>>>>>>> error in splash screen: $e');
      if (!mounted) return false;
      return true;
    }
  }

  // 강제 다이얼로그
  void _showUpdateDialog(String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // 안드로이드 뒤로가기 버튼 무력화 (강제)
          child: AlertDialog(
            title: const Text('필수 업데이트 안내'),
            content: const Text('안정적인 서비스 이용을 위해\n최신 버전으로 업데이트해 주세요.'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse(storeUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('스토어로 이동'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // 검사하는 동안 빙글빙글
      );
    }

    if (_isInDB && _isInFirebase) {
      if (_user!.role == 'customer') return const CustomerHomeScreen();
      if ((_user!.companyId ?? '').trim().isNotEmpty) return HomeScreen();
      return CompanyEntryScreen(userId: _user!.id);
    } else {
      return LoginScreen();
    }
  }
}
