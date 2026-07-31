import 'package:flutter/material.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';

/// 관리자용 추가, 삭제 가능한 테이블 UI
class AdminTableCard extends StatelessWidget {
  final TableModel table;
  final String companyId;
  final VoidCallback onChanged;
  final String userId;

  const AdminTableCard({
    super.key,
    required this.table,
    required this.companyId,
    required this.onChanged,
    required this.userId,
  });

  void _showRenameTableDialog(BuildContext context) {
    final controller = TextEditingController(text: table.tablename);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테이블 이름 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '새 테이블 이름 (예: VIP-1)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == table.tablename) return;

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await TableApi().updateTable(
                  tableId: table.id,
                  tableName: newName,
                  userId: userId,
                );

                navigator.pop(); // 로딩창
                navigator.pop(); // 수정창

                onChanged();
              } catch (e) {
                navigator.pop(); // 로딩창
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('수정 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              '수정',
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

  void _showDeleteTableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테이블 삭제'),
        content: Text('${table.tablename} 테이블을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await TableApi().deleteTable(tableId: table.id);

                navigator.pop(); // 로딩창
                navigator.pop(); // 삭제 확인창

                onChanged();
              } catch (e) {
                navigator.pop(); // 로딩창

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showRenameTableDialog(context),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              table.tablename,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => _showDeleteTableDialog(context),
            child: const Icon(
              Icons.remove_circle,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
