import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/company_api.dart';

class InviteCodeCard extends StatelessWidget {
  final CompanyModel company;
  final ValueChanged<CompanyModel> onCompanyChanged;
  InviteCodeCard({
    super.key,
    required this.company,
    required this.onCompanyChanged,
  });

  // 초대 코드 재발급
  void _showReissueDialog(BuildContext context, String companyId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('초대 코드 재발급'),
        content: const Text('코드를 재발급하면 기존 코드는 더 이상 사용할 수 없습니다.\n정말 변경하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                  ),
                  child: const Text('취소'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ontext) =>
                          const Center(child: CupertinoActivityIndicator()),
                    );
                    // DB 업데이트
                    try {
                      final updatedCompany = await CompanyApi()
                          .regenerateInviteCode(companyId: companyId);
                      onCompanyChanged(updatedCompany);
                      navigator.pop(); // 로딩창 끄기
                      navigator.pop(); // 재발급하시겠습니까? 팝업 끄기
                    } catch (e) {
                      navigator.pop(); // 로딩창 끄기
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('코드 재발급에 실패했습니다. 다시 시도해주세요'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      print("재발급 실패: $e");
                    }
                  },
                  child: const Text(
                    '재발급 실행',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String inviteCode = company.inviteCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '매장 초대 코드',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  company.inviteCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 30),
            Expanded(
              child: IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.black87),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
                  );
                },
              ),
            ),
            Expanded(
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh, size: 20, color: Colors.black),
                onPressed: () => _showReissueDialog(context, company.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
