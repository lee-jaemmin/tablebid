import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/screens/address_screen.dart';
import 'package:tablebid/screens/home_screen.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/services/address_api.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/user_api.dart';

class CompanyEntryScreen extends StatefulWidget {
  final String userId;
  CompanyEntryScreen({super.key, required this.userId});

  @override
  State<CompanyEntryScreen> createState() => _CompanyEntryScreenState();
}

class _CompanyEntryScreenState extends State<CompanyEntryScreen> {
  final _companyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? realAddr = null;

  @override
  void dispose() {
    _companyNameController.dispose();
    _inviteCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// [Func] 직원이 친 코드 보고 특정 회사로 보내는 함수
  Future<void> _joinCompanyWithCode(String code) async {
    final String upperCode = code.toUpperCase(); // 소문자로 쳐도 대문자로 변환하여 검색
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 로딩창
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator()),
    );

    try {
      final company = await CompanyApi().getCompanyByCode(upperCode);
      await UserApi().updateUser(userId: widget.userId, companyId: company.id);

      if (!mounted) return;
      navigator.pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('매장 입장 중 오류 발생.')));
      print('❌ 코드로 회사 가져오는 중 오류 발생: $e');
    }
  }

  /// [UI: 팝업] 초대 코드 입력
  void _showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("초대 코드 입력"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("사장님께 전달받은 6자리 코드를 입력해주세요."),
            const SizedBox(height: 16),
            TextField(
              controller: _inviteCodeController,
              decoration: const InputDecoration(
                hintText: "예: X7P9K2",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters, // 자동 대문자
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "취소",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final code = _inviteCodeController.text.trim();

                    if (code.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('초대 코드는 6자리입니다. 6자리를 정확히 입력해주세요.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context); // 팝업 창 닫기
                    _joinCompanyWithCode(code);
                    print(">>>>>>>>>>>입력된 코드: ${_inviteCodeController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    "입장하기",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [Func] 매장 생성 및 DB 등록 함수
  Future<void> _createCompany() async {
    final companyName = _companyNameController.text.trim();
    final address = _addressController.text.trim();
    if (companyName.isEmpty) return;
    if (address.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 입력 팝업 닫기
    Navigator.pop(context);

    // 로딩창
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator()),
    );

    try {
      final company = await CompanyApi().createCompany(
        name: companyName,
        address: address,
      );
      await UserApi().updateUser(
        userId: widget.userId,
        companyId: company.id,
        role: 'owner',
      );

      if (!mounted) return;
      navigator.pop(); // 로딩창 닫기

      // 홈 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('매장 생성 중 오류 발생.')));
      print('❌ 매장 생성 중 오류 발생: $e');
    }
  }

  Future<void> _onAddressTap() async {
    final address = await Navigator.push<AddressResult>(
      context,
      MaterialPageRoute(builder: (context) => AddressScreen()),
    );
    if (address == null || !mounted) return;
    _addressController.text = address.roadAddr;
  }

  /// [UI: 팝업] 새 매장 등록
  void _showCreateCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("새 매장 등록"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "매장 이름",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                hintText: "매장 이름은 변경할 수 없으니 신중하게 입력해주세요.",
              ),
              minLines: null,
              maxLines: null,
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
            const Text(
              "주소",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _onAddressTap,
                    child: InputDecorator(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _addressController,
                        builder: (context, value, child) {
                          final addressText = value.text.trim();
                          return Text(
                            addressText.isEmpty
                                ? '도로명, 건물명, 번지 검색'
                                : addressText,
                          );
                        },
                      ),
                      decoration: const InputDecoration(
                        hintText: "EX) 이태원",
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "취소",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_companyNameController.text.trim().isEmpty ||
                              _addressController.text.trim().isEmpty)
                            return; // 매장 이름이 비어있으면 return
                          await _createCompany(); // 매장 생성 로직 실행
                        },
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.black26,
                          ),
                        )
                      : Text('생성하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [Func] 로그아웃 함수
  Future<void> _handleLogout() async {
    // 1. 파이어베이스 세션 종료 (이걸 안 하면 자동 로그인됨)
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // 2. 로그인 화면으로 이동하며 기존 히스토리를 모두 제거 (뒤로 가기 방지)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /// [Func] 회원 탈퇴 함수
  Future<void> _handleWithdrawal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 재확인 팝업
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("회원 탈퇴"),
            content: const Text(
              "정말로 GRID를 떠나시겠습니까?\n모든 데이터가 즉시 삭제되며 복구할 수 없습니다.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소", style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("탈퇴하기", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // 로딩 시작
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CupertinoActivityIndicator()),
    );

    try {
      final uid = user.uid;

      // 카카오 로그인 유저면 카카오 연결 해제 시도
      try {
        await kakao.UserApi.instance.unlink();
      } catch (_) {}

      // 기존 Firestore 유저 문서 삭제
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // Firebase Auth 계정 삭제
      await user.delete();

      // FastAPI 유저 삭제
      await UserApi().deleteUser(userId: uid);

      // 성공 시 로딩창 닫고 로그아웃 진행
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')));

      // 기존에 만들어둔 로그아웃 함수 호출 (알아서 LoginScreen으로 이동함)
      await _handleLogout();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context); // 로딩창 닫기

      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보안 정책에 의해 재로그인이 필요합니다. 다시 로그인 후 탈퇴해주세요.'),
          ),
        );

        await FirebaseAuth.instance.signOut();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Firebase 계정 삭제 실패: ${e.code}')));
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context); // 로딩창 닫기

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: _handleLogout,
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              onPressed: _handleWithdrawal,
              icon: Icon(
                Icons.person_remove,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "반갑습니다!\nTABLE BID를 시작해볼까요?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "역할에 맞는 버튼을 선택해주세요.",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '사장님/매니저님이신가요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildEntryCard(
                title: "새 매장 등록하기",
                subtitle: "우리 매장의 등록을 시작합니다.",
                icon: Icons.add_business_outlined,
                onTap: _showCreateCompanyDialog,
              ),
              const SizedBox(height: 40),
              Text(
                '직원이신가요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildEntryCard(
                title: "초대 코드로 입장하기",
                subtitle: "사장님께 코드를 받으셨나요?",
                icon: Icons.vpn_key_outlined,
                onTap: _showInviteCodeDialog,
              ),
              SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => CupertinoActivityIndicator(),
                          barrierDismissible: false,
                        );
                        try {
                          await UserApi().updateUser(
                            userId: widget.userId,
                            role: "customer",
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          print('손님입니다 중 오류: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('입장 처리 중 오류가 발생했습니다. 다시 시도해주세요.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text('손님입니다', style: TextStyle(fontSize: 20)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard({
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
