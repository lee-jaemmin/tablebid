import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/services/websocket_service.dart';

class CustomerSettingScreen extends StatefulWidget {
  const CustomerSettingScreen({super.key});

  @override
  State<CustomerSettingScreen> createState() => _CustomerSettingScreenState();
}

class _CustomerSettingScreenState extends State<CustomerSettingScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('로그인이 필요합니다.');
      final user = await UserApi().getUser(firebaseUser.uid);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러오지 못했습니다.')),
      );
    }
  }

  Future<void> _signOutAndNavigate(BuildContext context) async {
    try {
      await WebsocketService.instance.disconnect();
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _withdrawMembership(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user가 존재하지 않습니다')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final uid = user.uid;
      try {
        await kakao.UserApi.instance.unlink();
      } catch (_) {}
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await user.delete();
      await UserApi().deleteUser(userId: uid);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보안 정책에 의해 재로그인이 필요합니다. 다시 로그인 후 탈퇴해주세요.')),
        );
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase 계정 삭제 실패: ${e.code}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '애플 앱스토어 규정 및 2026 보안 가이드라인에 따라, 탈퇴 즉시 귀하의 모든 개인정보와 식별 데이터는 서버에서 영구 삭제(익명화)됩니다. '
          '탈퇴 보류 기간이 없으므로 삭제된 데이터는 복구할 수 없습니다. 정말 탈퇴하시겠습니까?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _withdrawMembership(context);
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), elevation: 0.5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.warning_amber, size: 18),
            title: const Text('노쇼'),
            trailing: _statusBadge('${_user?.noShowCount ?? 0}회', Colors.orange),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone_android, size: 18),
            title: const Text('번호 인증'),
            trailing: _statusBadge(
              _user?.phoneVerified == true ? '인증 완료' : '인증 안 됨',
              _user?.phoneVerified == true ? Colors.green : Colors.red,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, size: 18),
            title: const Text('로그아웃'),
            onTap: () => _signOutAndNavigate(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_remove, size: 18, color: Colors.red),
            title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () => _showWithdrawDialog(context),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
