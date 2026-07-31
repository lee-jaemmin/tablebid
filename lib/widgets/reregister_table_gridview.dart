import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_history_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/history_api.dart';

class ReregisterTableGridView extends StatelessWidget {
  final String companyId;
  final List<TableModel> tables;
  final TableHistoryModel historyData;

  ReregisterTableGridView({
    super.key,
    required this.companyId,
    required this.tables,
    required this.historyData,
  });

  @override
  Widget build(BuildContext context) {
    tables.sort((a, b) => naturalSortCompare(a.tablename, b.tablename));
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final targetTable = tables[index];
        // [조건] 빈 테이블(available)만 선택 가능하게 설정
        bool isAvailable = targetTable.status == 'available';

        return GestureDetector(
          onTap: isAvailable
              ? () => _confirmReregister(context, targetTable)
              : null,
          child: Card(
            color: isAvailable ? Colors.green[50] : Colors.grey[300],
            child: Center(
              child: Text(
                targetTable.tablename,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmReregister(BuildContext context, TableModel targetTable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정보 재등록'),
        content: Text(
          '${historyData.customerName}님의 정보를\n${targetTable.tablename}번 테이블로 재등록하시겠습니까?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              ); // 프로그레스바
              try {
                await HistoryApi().reRegisterTable(
                  historyId: historyData.id,
                  tableId: targetTable.id,
                );
                if (context.mounted) {
                  Navigator.pop(context); // 프로그레스바 닫기
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // ReregisterScreen 닫기
                  Navigator.pop(context); // HistoryBottomSheet 닫기
                }
              } catch (e) {
                Navigator.pop(context); // 로딩바끄기
                Navigator.pop(context); // 윈도우 끄기
                print(e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('재등록 실패: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              '확정',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
