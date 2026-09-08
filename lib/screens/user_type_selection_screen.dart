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
      await UserApi().setUserAsCustomer();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      print('>>>>>>>>>>>>>>>>.사용자 유형 저장 오류: $e');
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
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '어떤 목적으로\n이용하시나요?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '사용자 유형에 맞는 항목을 선택해주세요.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTypeCard(
                      title: '손님으로 이용하기',
                      subtitle: '매장을 검색하고 예약할 수 있습니다.',
                      icon: Icons.person_outline,
                      onTap: _selectCustomer,
                    ),
                    const SizedBox(height: 20),
                    _buildTypeCard(
                      title: '직원 또는 사장으로 이용하기',
                      subtitle: '매장을 등록하거나 초대 코드로 입장합니다.',
                      icon: Icons.storefront_outlined,
                      onTap: _selectStaff,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
