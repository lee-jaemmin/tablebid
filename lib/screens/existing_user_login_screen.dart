import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tablebid/constants/gaps.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/screens/password_reset_screen.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/widgets/auth_textfield.dart';
import 'home_screen.dart';

class ExistingUserLogin extends StatefulWidget {
  const ExistingUserLogin({super.key});

  @override
  State<ExistingUserLogin> createState() => _ExistingUserLoginState();
}

class _ExistingUserLoginState extends State<ExistingUserLogin> {
  bool isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailValid = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    // 로그인에서는 비밀번호가 6자리인지 실시간으로 검사할 필요 없이, 맞는지 틀린지만 보면 됩니다.
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final text = _emailController.text.trim();
    if (text.isEmpty) {
      setState(() => _isEmailValid = true);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isValid = emailRegex.hasMatch(text);

    if (_isEmailValid != isValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  bool _isFormValid() {
    if (isLoading) return false;
    return _isEmailValid &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _routeUserByCompanyStatus(User user) async {
    try {
      final apiUser = await UserApi().getUser(user.uid);
      final fcmtoken = await FirebaseMessaging.instance.getToken();

      if (fcmtoken != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
                {
                  'fcmtoken': fcmtoken,
                },
                SetOptions(merge: true),
              );

          //DB에도 저장
          await UserApi().updateUser(
            userId: user.uid,
            fcmToken: fcmtoken,
          );
        } catch (e) {
          print("FCM 토큰 업데이트 실패: $e");
        }
      }

      final hasCompany = (apiUser.companyId ?? '').trim().isNotEmpty;

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => hasCompany
              ? HomeScreen()
              : CompanyEntryScreen(
                  userId: user.uid,
                ),
        ),
        (context) => false,
      );
    } catch (e) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("등록되지 않았거나 정보를 불러올 수 없는 계정입니다.")),
      );

      print("라우팅 체크 중 에러: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final String userEmail = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: userEmail,
            password: password,
          );

      if (mounted) {
        await _routeUserByCompanyStatus(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String message = "아이디 또는 비밀번호가 잘못되었습니다.";
      if (e.code == 'invalid-email') {
        message = "아이디 형식이 올바르지 않습니다.";
      } else if (e.code == 'user-disabled') {
        message = "정지된 계정입니다.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // 🌟 뒤로 가기를 위한 투명 앱바 추가
        appBar: AppBar(
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "기존 계정 로그인",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "이전에 가입하신 이메일로 로그인해주세요.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 이메일
                  AuthTextfield(
                    controller: _emailController,
                    hintText: "이메일",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  if (!_isEmailValid && _emailController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "올바른 이메일 형식이 아닙니다.",
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ),

                  // 비밀번호
                  AuthTextfield(
                    controller: _passwordController,
                    hintText: "비밀번호",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isFormValid() ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "로그인",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 비밀번호 재설정
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordResetScreen(),
                        ),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            "비밀번호를 잊어버리셨나요?",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          Gaps.h12(context),
                          Text(
                            "비밀번호 재설정",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // 하단 여백
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
