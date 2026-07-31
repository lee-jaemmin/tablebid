import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/services/user_api.dart';

Future<void> CheckAdminAndNavigate({
  required BuildContext context,
  required Widget designatedPage,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  void _showSimpleDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  if (currentUser == null) {
    _showSimpleDialog(context, '로그인 필요', '로그인이 필요한 서비스입니다.');
    return;
  }

  try {
    /// 현재 유저의 정보(role) 가져오기
    final user = await UserApi().getUser(currentUser.uid);
    final role = user.role;

    if (role == 'admin' || role == 'owner') {
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => designatedPage),
        );
      }
    } else {
      if (context.mounted) {
        _showSimpleDialog(context, '권한 없음', '관리자만 사용 가능한 메뉴입니다.');
        return;
      }
    }
  } catch (e) {
    print('권한 기능 체크 에러 $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
      ),
    );
  }
}