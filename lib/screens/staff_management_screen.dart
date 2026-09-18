import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/services/user_api.dart';

class StaffmanagementScreen extends StatefulWidget {
  final String companyId;
  const StaffmanagementScreen({super.key, required this.companyId});

  @override
  State<StaffmanagementScreen> createState() => _StaffmanagementScreenState();
}

class _StaffmanagementScreenState extends State<StaffmanagementScreen> {
  List<UserModel> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final fectchedUsers = await UserApi().getUsersByCompnay(widget.companyId);
      if (!mounted) return;
      setState(() {
        users = fectchedUsers;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('직원 목록 로딩 실패: $e')),
      );
    }
  }

  /// [Func] 사장 권한 넘기기
  Future<void> _transferOwnership(
    BuildContext context,
    String newOwnerUid,
    String newOwnerName,
  ) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("사장 권한 위임"),
            content: Text(
              "'$newOwnerName' 님에게 사장 권한을 넘기시겠습니까?\n위임 후 대표님은 '일반 직원' 권한으로 변경되며, 이후 회원 탈퇴가 가능합니다.",
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text(
                        "취소",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text(
                        "위임 확정",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final myUid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await UserApi().changeOwner(targetUserId: newOwnerUid);
      if(!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        if(!mounted) return;
        Navigator.pop(context); // 로딩창 끄기
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("위임 실패: $e")));
      }
    }
    await loadData();
  }

  /// [Func] 권한 변경
  Future<void> _updateRole(String uid, String newRole) async {
    await UserApi().updateUser(userId: uid, role: newRole);
    await loadData();
  }

  /// [Func] 직원 내보내기
  Future<void> _kickuser(BuildContext context, String uid, String name) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("직원 내보내기"),
            content: Text(
              "'$name' 직원을 매장에서 내보내시겠습니까?\n해당 직원은 즉시 매장 데이터에 접근할 수 없게 됩니다.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("내보내기", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final user = await UserApi().getUser(uid);
        await UserApi().removeUserFromCompany(targetUserId: user.id);
        await loadData();
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('내보내기 실패')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("직원 관리"),
        elevation: 0.5,
      ),
      body: isLoading ? const Center(child: const CircularProgressIndicator())
      : users.isEmpty
          ? const Center(child: Text("소속된 직원이 없습니다."))
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                final String uid = user.id;
                final String role = user.role!;
                final bool isMe = role == 'owner'; // 나(사장님)는 관리 대상에서 제외

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMe ? Colors.black : Colors.grey[200],
                    child: Icon(
                      isMe ? Icons.stars : Icons.person,
                      color: isMe ? Colors.yellow : Colors.grey,
                    ),
                  ),
                  title: Text("${user.userName} ${isMe ? '(나)' : ''}"),
                  subtitle: Text("권한: $role"),
                  trailing: isMe
                      ? null
                      : PopupMenuButton<String>(
                          color: Colors.white,
                          onSelected: (value) {
                            if (value == 'admin') _updateRole(uid, 'admin');
                            if (value == 'user') _updateRole(uid, 'user');
                            if (value == 'kick')
                              _kickuser(context, uid, user.userName);
                            if (value == 'transfer')
                              _transferOwnership(context, uid, user.userName);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: role == 'admin' ? 'user' : 'admin',
                              child: Text(
                                role == 'admin' ? "일반 직원으로 변경" : "관리자 권한 부여",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'kick',
                              child: Text('내보내기', style: TextStyle(color: Colors.black),),
                            ),
                            const PopupMenuItem(
                              value: 'transfer',
                              child: Text(
                                "사장 권한 위임",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
