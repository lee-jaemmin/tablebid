import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/services/websocket_service.dart';

class CustomerSettingScreen extends StatelessWidget {
  const CustomerSettingScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), elevation: 0.5),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, size: 18),
            title: const Text('로그아웃'),
            onTap: () => _signOutAndNavigate(context),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
