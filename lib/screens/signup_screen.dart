import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/screens/user_type_selection_screen.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/widgets/agree_checkbox.dart';
import 'package:tablebid/widgets/auth_textfield.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// 일반 회원 가입 코드
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용약관 및 개인정보처리방침에 동의해주세요.')),
      );
      return;
    }

    final inputEmail = _emailController.text.trim();
    final userName = _nameController.text.trim();
    final inputPassword = _passwordController.text.trim();

    if (inputEmail.isEmpty || inputPassword.isEmpty || userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 아이디, 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    // 이메일 정규식 검사
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(inputEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')),
      );
      return;
    }

    setState(() => isLoading = true);

    

    try {
      UserCredential userCredential;
      String? fcmtoken;
      try {
        final messeging = FirebaseMessaging.instance;
        await messeging.requestPermission();
        if(defaultTargetPlatform == TargetPlatform.iOS) {
          final apnToken = await messeging.getAPNSToken();

          if(apnToken != null) {
            fcmtoken = await messeging.getToken();
          } else {
            print('apn token 발급 안되어서 fcm 발급 보류');
          }
        }
      } catch (e) {
        print('FCM 토큰 발급 보류: $e');
      }

      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: inputEmail,
            password: inputPassword,
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': inputEmail,
            'createdat': FieldValue.serverTimestamp(),
            'fcmtoken': fcmtoken,
          });

      await UserApi().createUser(
        userId: userCredential.user!.uid,
        email: inputEmail,
        fcmtoken: fcmtoken,
        userName: userName,
        role: 'user',
        cardFields: ['purchases', 'persons'],
      );

      print('>>>>>>>> 일반 회원가입: 새로 가입한 uid: ${userCredential.user!.uid}');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserTypeSelectionScreen(userId: userCredential.user!.uid),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "회원가입에 실패했습니다.";

      if (e.code == 'email-already-in-use') {
        message = "이미 가입된 이메일입니다. 로그인 화면을 이용해주세요.";
      } else if (e.code == 'weak-password') {
        message = "비밀번호는 6자리 이상이어야 합니다.";
      } else if (e.code == 'invalid-email') {
        message = "유효하지 않은 이메일 형식입니다.";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('❌ 일반 회원가입 에러: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 중 문제가 발생했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "직접 회원가입",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
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
                    "TABLE BID",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "사용할 아이디와 비밀번호를 입력해주세요.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 이름 입력
                  AuthTextfield(
                    controller: _nameController,
                    hintText: "이름 입력",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  // 아이디 입력 (안내 문구 단순화)
                  AuthTextfield(
                    controller: _emailController,
                    hintText: "이메일 입력",
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력 (필수 입력으로 변경)
                  AuthTextfield(
                    controller: _passwordController,
                    hintText: "비밀번호 입력 (6자리 이상)",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),

                  // 약관 동의 섹션
                  AgreeCheckbox(
                    title: "이용약관 동의 (필수)",
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    onTapTitle: () => _launchURL(
                      "https://sites.google.com/view/grid-conditionterms?usp=sharing",
                    ),
                  ),
                  const SizedBox(height: 8),
                  AgreeCheckbox(
                    title: "개인정보처리방침 동의 (필수)",
                    value: _agreedToPrivacy,
                    onChanged: (v) =>
                        setState(() => _agreedToPrivacy = v ?? false),
                    onTapTitle: () => _launchURL(
                      "https://sites.google.com/view/gridprivatepolicy?usp=sharing",
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 제출 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "가입 및 입장하기",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
