import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';

class MoveTableGridView extends StatelessWidget {
  final String companyId;
  final List<TableModel> tables;
  final TableModel fromTable;
  final String userId;

  MoveTableGridView({
    required this.companyId,
    required this.tables,
    required this.fromTable,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    tables.sort((a, b)=>naturalSortCompare(a.tablename, b.tablename));
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
        bool isAvailable = targetTable.status == 'available';

        return GestureDetector(
          onTap: isAvailable ? () => _confirmMove(context, targetTable) : null,
          child: Card(
            // 사용 중이면 회색, 이동 가능하면 파란색
            color: isAvailable ? Colors.blue[100] : Colors.grey[300],
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

  void _confirmMove(BuildContext context, TableModel targetTable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 이동'),
        content: Text(
          '${fromTable.tablename}의 정보를 ${targetTable.tablename}으로 이동하시겠습니까?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      await TableApi().moveTable(fromTableId: fromTable.id, toTableId: targetTable.id);
                      if (context.mounted) {
                        Navigator.pop(context); // 프로그레스바 닫기
                        Navigator.pop(context); // 다이얼로그 닫기
                        Navigator.pop(context); // 이동 화면 닫기
                        Navigator.pop(context); // 인포윈도우 닫기
                      }
                    } catch (e) {
                      print(e);
                      if (context.mounted) {
                        Navigator.pop(context); // 프로그레스바 닫기
                        Navigator.pop(context); // 다이얼로그 닫기
                
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('이동 중 오류 발생: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    '이동 확정',
                    style: TextStyle(
                      color: Colors.black,
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
}
