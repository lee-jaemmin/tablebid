import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/screens/existing_user_login_screen.dart';
import 'package:tablebid/screens/signup_screen.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tablebid/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginLoading = false;

  Future<bool> getFastApiUser(String userId) async {
    try {
      await UserApi().getUser(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// [Func] 카카오 로그인 및 파이어베이스 연동 로직
  Future<void> signInWithKakao(BuildContext context) async {
    setState(() => _isLoginLoading = true);

    bool isLoginRecoverableError(auth.FirebaseAuthException e) {
      return e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password';
    }

    try {
      // 1. 카카오 로그인 인증
      final bool isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          if (e is PlatformException && e.code == 'CANCELED') {
            if (context.mounted) {
              setState(() => _isLoginLoading = false);
            }
            return;
          }

          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 2. 카카오 유저 정보 획득
      final kakao.User kakaoUser = await kakao.UserApi.instance.me();

      final String kakaoUid = kakaoUser.id.toString();
      final String nickname =
          kakaoUser.kakaoAccount?.profile?.nickname ?? '이름없음';

      final String? realEmailRaw = kakaoUser.kakaoAccount?.email;
      final String? realEmail = realEmailRaw?.trim();
      final bool hasRealEmail = realEmail != null && realEmail.isNotEmpty;

      // 기존 레거시 dummy 유저 로그인용으로만 사용
      final String dummyEmail = 'kakao_$kakaoUid@grid.com';
      final String dummyPassword = 'kakao_PW_$kakaoUid!';

      auth.UserCredential? userCredential;
      bool isLegacyDummyUser = false;
      bool isNewUser = false;
      String? fcmtoken;

      // 3-1 카카오 기존 계정 우선 로그인
      if (hasRealEmail) {
        try {
          userCredential = await auth.FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: realEmail,
                password: dummyPassword,
              );

          print('✅ 카카오 realEmail 기존 유저 로그인 성공: $realEmail');
        } on auth.FirebaseAuthException catch (e) {
          if (!isLoginRecoverableError(e)) {
            rethrow;
          }

          print('ℹ️ realEmail 로그인 실패, 레거시 dummy 확인으로 진행: ${e.code}');
        }
      }

      // 3-2. 안되면 legacy dummyEmail 로그인 시도
      if (userCredential == null) {
        try {
          userCredential = await auth.FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: dummyEmail,
                password: dummyPassword,
              );

          isLegacyDummyUser = true;
          print('✅ 카카오 레거시 dummyEmail 유저 로그인 성공: $dummyEmail');
        } on auth.FirebaseAuthException catch (e) {
          if (!isLoginRecoverableError(e)) {
            rethrow;
          }

          print('ℹ️ legacy dummyEmail 로그인 실패: ${e.code}');
        }
      }

      // 3-3. 신규 가입: firebase, db 둘 다 처리
      if (userCredential == null) {
        if (!hasRealEmail) {
          throw Exception(
            '카카오 이메일 정보가 없어 가입을 진행할 수 없습니다. '
            '카카오 계정의 이메일 제공에 동의한 뒤 다시 시도해주세요.',
          );
        }
        try {
          // firebase 저장할 거
          userCredential = await auth.FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: realEmail,
                password: dummyPassword,
              );

          isNewUser = true;
          print('✅ 카카오 realEmail 신규 가입 성공: $realEmail');
        } on auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            throw Exception(
              '이미 다른 방식으로 가입된 이메일입니다. '
              '기존 이메일 로그인 또는 Apple 로그인 여부를 확인해주세요.',
            );
          }
          rethrow;
        }
      }

      final auth.User firebaseUser = userCredential.user!;
      fcmtoken = await FirebaseMessaging.instance.getToken();
      final email = firebaseUser.email ?? realEmail ?? dummyEmail;

      print('>>>>>>>>>> 카카오 로그인 Firebase uid: ${firebaseUser.uid}');
      print('>>>>>>>>>> Firebase email: ${firebaseUser.email}');
      print('>>>>>>>>>> Kakao uid: $kakaoUid');
      print('>>>>>>>>>> legacy dummy user: $isLegacyDummyUser');
      print('>>>>>>>>>> new user: $isNewUser');
      print('>>>>>>>>>> 토큰: $fcmtoken');

      // Firebase에 정보 저장
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);
      await userDocRef.set({
        'email': email,
        if (fcmtoken != null) 'fcmtoken': fcmtoken,
        if (isNewUser) 'createdat': FieldValue.serverTimestamp(),
        'updatedat': FieldValue.serverTimestamp(),
      });

      UserModel user;
      final isInDb = await getFastApiUser(firebaseUser.uid);
      if (isNewUser) {
        // 3-3이면
        user = await UserApi().createUser(
          userId: firebaseUser.uid,
          userName: nickname,
          email: realEmail!,
          role: 'user',
          fcmtoken: fcmtoken,
          cardFields: ['purchases', 'persons'],
        );
      } else {
        // 기존 유저고 db에 있으면
        // 토큰 업데이트
        if (isInDb == true) {
          user = await UserApi().getUser(firebaseUser.uid);
          user = await UserApi().updateUser(
            userId: firebaseUser.uid,
            fcmToken: fcmtoken,
          );
        } else {
          // db에 없으면
          user = await UserApi().createUser(
            userId: firebaseUser.uid,
            userName: nickname,
            email: email,
            role: 'user',
            fcmtoken: fcmtoken,
            cardFields: ['purchases', 'persons'],
          );
        }
      }

      setState(() => _isLoginLoading = false);

      if (user.companyId != null && user.companyId != 'null') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyEntryScreen(
              userId: user.id,
            ),
          ),
        );
      }
    } catch (error) {
      print('❌ 카카오 로그인 에러: $error');

      if (context.mounted) {
        setState(() => _isLoginLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceAll('Exception: ', ''),
            ),
          ),
        );
      }
    }
  }

  void _showLegacyEmailLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExistingUserLogin()),
    );
  }

  /// [Func] 애플 로그인
  Future<void> signInWithApple(BuildContext context) async {
    setState(() => _isLoginLoading = true);

    try {
      // 애플 서버에 로그인 요청 (얼굴인식/비밀번호)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 파이어베이스가 알아들을 수 있는 인증서(Credential)로 변환
      final oauthCredential = auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 파이어베이스 로그인 (자동으로 가입/로그인 처리)
      final userCredential = await auth.FirebaseAuth.instance
          .signInWithCredential(oauthCredential);

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid);
        final fcmtoken = await FirebaseMessaging.instance.getToken();
        final email = firebaseUser.email ?? appleCredential.email;

        // 애플: '최초 1회' 가입 시에만 '이름'을 던져줍니다.
        String nickname = '이름없음';
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          // 성(familyName) + 이름(givenName) 조합 (예: 홍 + 길동)
          nickname =
              '${appleCredential.familyName ?? ''}${appleCredential.givenName ?? ''}';
        }

        final isInDb = await getFastApiUser(firebaseUser.uid);

        if (isInDb == true) {
          await userDocRef.set({
            'fcmtoken': fcmtoken,
            'updatedat': FieldValue.serverTimestamp(),
          });
          await UserApi().updateUser(
            userId: firebaseUser.uid,
            fcmToken: fcmtoken,
          );
        } else {
          await userDocRef.set({
            'email': email,
            if (fcmtoken != null) 'fcmtoken': fcmtoken,
            'createdat': FieldValue.serverTimestamp(),
            'updatedat': FieldValue.serverTimestamp(),
          });
          await UserApi().createUser(
            userId: firebaseUser.uid,
            userName: nickname,
            email: email ?? '',
            role: 'user',
            fcmtoken: fcmtoken,
            cardFields: ['purchases', 'persons'],
          );
        }

        // 4. 로그인 완료 후 라우팅 분기 처리
        if (!context.mounted) return;

        final user = await UserApi().getUser(firebaseUser.uid);

        setState(() => _isLoginLoading = false);

        // companyid비었나 체크
        final String? companyId = user.companyId;

        if (companyId != null && companyId != 'null' && companyId != '') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyEntryScreen(userId: user.id),
            ),
          );
        }
      }
    } catch (error) {
      print('❌ 애플 로그인 에러: $error');
      setState(() => _isLoginLoading = false);
      if (context.mounted) {
        // 사용자가 로그인 창을 그냥 닫은 경우(Canceled) 에러 메시지 띄우지 않음
        if (error is SignInWithAppleAuthorizationException &&
            error.code == AuthorizationErrorCode.canceled) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('애플 로그인 중 문제가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GRID",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "스마트한 매장 관리의 시작",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 80),

              if (_isLoginLoading)
                const CircularProgressIndicator()
              else ...[
                // 1. 카카오 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                    onPressed: () => signInWithKakao(context),
                    child: const Text(
                      "카카오로 시작하기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 애플 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => signInWithApple(context),
                    child: const Text(
                      "Apple로 시작하기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 일반 가입
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                    child: const Text(
                      "일반 회원가입",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 3. 기존 유저 로그인 (레거시)
                GestureDetector(
                  onTap: _showLegacyEmailLogin,
                  child: const Text(
                    "기존 이메일로 로그인하기",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
