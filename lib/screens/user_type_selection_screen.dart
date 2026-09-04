import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/services/user_api.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String userId;

  const UserTypeSelectionScreen({super.key, required this.userId});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectCustomer() async {
    setState(() => _isLoading = true);
    try {
      await UserApi().updateUser(userId: widget.userId, role: 'customer');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 유형을 저장하지 못했습니다. 다시 시도해주세요.')),
      );
    }
  }

  void _selectStaff() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyEntryScreen(userId: widget.userId),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 유형 선택')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '어떤 목적으로 이용하시나요?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectCustomer,
                        child: const Text('손님으로 이용하기'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectStaff,
                        child: const Text('직원 또는 사장으로 이용하기'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
