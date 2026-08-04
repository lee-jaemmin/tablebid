import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/screens/staff_management_screen.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingScreen extends StatefulWidget {
  final UserModel initialUser;

  const SettingScreen({super.key, required this.initialUser});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  static const List<String> _defaultTableCardFields = ['purchases', 'persons'];
  static const Map<String, String> _tableCardFieldLabels = {
    'purchases': '구매목록',
    'price': '가격',
    'persons': '인원',
    'staff': '담당 스태프',
    'remark': '비고',
  };

  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.initialUser;
  }

  Future<void> _updateUsername(BuildContext context, String username) async {
    try {
      final updatedUser = await UserApi().updateUser(
        userId: _currentUser.id,
        userName: username,
      );

      if (!context.mounted) return;
      setState(() {
        _currentUser = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름이 변경되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이름 변경 실패: $e')));
    }
  }

  void _showUsernameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == currentName) return;

              Navigator.pop(dialogContext);
              await _updateUsername(context, newName);
            },
            child: const Text('변경', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  List<String> _sanitizeTableCardFields(List<String> rawFields) {
    final fields = rawFields
        .map((field) => field.toString())
        .where(_tableCardFieldLabels.containsKey)
        .take(2)
        .toList();

    return fields.length == 2 ? fields : _defaultTableCardFields;
  }

  Future<void> _updateTableCardFields(
    BuildContext context,
    List<String> fields,
  ) async {
    try {
      final updatedUser = await UserApi().updateUser(
        userId: _currentUser.id,
        cardfields: fields,
      );

      if (!context.mounted) return;
      setState(() {
        _currentUser = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테이블 카드 표시 설정이 변경되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('설정 변경 실패: $e')));
    }
  }

  void _showTableCardFieldsDialog(
    BuildContext context,
    List<String> selectedFields,
  ) {
    final selected = selectedFields.toSet();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('테이블 카드 표시 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _tableCardFieldLabels.entries.map((entry) {
                  final isSelected = selected.contains(entry.key);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(entry.value),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          if (selected.length >= 2) return;
                          selected.add(entry.key);
                        } else {
                          selected.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: selected.length == 2
                      ? () async {
                          Navigator.pop(dialogContext);
                          await _updateTableCardFields(
                            context,
                            selected.toList(),
                          );
                        }
                      : null,
                  child: const Text('저장', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // logout Function
  Future<void> _signOutAndNavigate(BuildContext context) async {
    try {
      await WebsocketService.instance.disconnect();
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // 모든 이전 라우트를 제거 (false 반환)
        );
      }
    } catch (e) {
      print("로그아웃 오류: $e");
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

      if (!context.mounted) return;

      Navigator.pop(context); // 로딩창 닫기

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase 계정 삭제 실패: ${e.code}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context); // 로딩창 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 탈퇴 재확인 팝업 (실시간 currentRole을 받도록 수정)
  void _showWithdrawDialog(
    BuildContext context,
    UserModel currentUser,
    String currentRole,
  ) async {
    if (currentRole == 'owner') {
      // 소속원 수를 세기 위해 잠깐 로딩
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 현재 회사에 소속된 유저가 몇 명인지 파이어베이스에서 검색
        final users = await UserApi().getUsersByCompnay(currentUser.companyId!);

        final memberCount = users.length;

        if (!context.mounted) return;
        Navigator.pop(context); // 로딩창 닫기

        // 소속원이 2명 이상일 때만 위임 팝업을 띄우고 함수를 종료합니다.
        if (memberCount >= 2) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('사장님 권한 위임 필요'),
              content: const Text(
                '현재 매장의 사장(Owner) 권한을 가지고 계십니다. '
                '탈퇴하시려면 먼저 다른 직원에게 사장 권한을 위임해야 합니다.\n\n확인 버튼을 누르면 직원 관리 화면으로 이동합니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 팝업 닫기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffmanagementScreen(
                          companyId: currentUser.companyId!,
                        ),
                      ),
                    );
                  },
                  child: const Text('확인', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          );
          return; // 위임이 필요하므로 여기서 탈퇴 프로세스 중단
        }

        // memberCount가 1명(본인 혼자)이라면 이 if문을 무사히 빠져나가
        // 아래의 일반 탈퇴 로직으로 자연스럽게 넘어가게 됩니다!
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // 로딩창 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보를 불러오는 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
        return;
      }
    }
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

  Future<void> _reAssignToken(BuildContext context, UserModel user) async {
    try {
      final uid = user.id;
      print('uid: $uid');
      final fcmtoken = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmtoken': fcmtoken,
        },
        SetOptions(merge: true),
      );
      await UserApi().updateUser(userId: uid, fcmToken: fcmtoken);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('토큰 재발급 성공'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('토큰 재발급 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('토큰 재발급 실패'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableCardFields = _sanitizeTableCardFields(_currentUser.cardfields);
    final tableCardFieldText = tableCardFields
        .map((field) => _tableCardFieldLabels[field])
        .whereType<String>()
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, size: 18),
            title: Text(_currentUser.userName),
            subtitle: const Text('이름'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUsernameDialog(context, _currentUser.userName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.table_chart, size: 18),
            title: const Text('테이블 카드 표시 항목'),
            subtitle: Text(tableCardFieldText),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTableCardFieldsDialog(context, tableCardFields),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.confirmation_number,
              size: 18,
            ),
            title: const Text(
              '알림이 오지 않나요?'
            ),
            subtitle: const Text('토큰 다시 발급 받기'),
            onTap: () => _reAssignToken(context, _currentUser),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout,
              size: 18,
            ),
            title: const Text('로그아웃'),
            onTap: () => _signOutAndNavigate(context),
          ),
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(
              Icons.person_remove,
              size: 18,
              color: Colors.red,
            ),
            title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () =>
                _showWithdrawDialog(context, _currentUser, _currentUser.role),
          ),
        ],
      ),
    );
  }
}
