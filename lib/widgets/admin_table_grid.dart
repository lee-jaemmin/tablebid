import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/admin_add_table_card.dart';
import 'package:tablebid/widgets/admin_table_card.dart';

class AdminTableGrid extends StatefulWidget {
  final String companyId;
  final String section;
  final String userId;

  const AdminTableGrid({
    super.key,
    required this.companyId,
    required this.section,
    required this.userId,
  });

  @override
  State<AdminTableGrid> createState() => _AdminTableGridState();
}

class _AdminTableGridState extends State<AdminTableGrid> {
  late Future<List<TableModel>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  void _loadTables() {
    _tablesFuture = TableApi().getTables(widget.companyId); // 나중에 명시적으로 선언할 때만 불러오기 위함.
  }

  void _reloadTables() {
    setState(() {
      _loadTables();
    });
  }

  void _showAddTableDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테이블 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '테이블 번호/이름 (예: A1)',
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
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
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final tablename = controller.text.trim();

                    if (tablename.isEmpty) return;

                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await TableApi().createTable(
                        tablename: tablename,
                        section: widget.section,
                        companyId: widget.companyId,
                      );

                      navigator.pop(); // 로딩창
                      navigator.pop(); // 테이블 추가 팝업

                      _reloadTables(); // 명시적으로 재로딩 하는 부분.
                    } catch (e) {
                      navigator.pop(); // 로딩창

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('테이블 추가 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('추가'),
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
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final isTablet = size.shortestSide > 600;
    final isLandScape = orientation == Orientation.landscape;

    final int crossAxisCount = isTablet
        ? (isLandScape ? 6 : 4)
        : (isLandScape ? 4 : 3);

    return FutureBuilder<List<TableModel>>(
      future: _tablesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('테이블 로딩 실패: ${snapshot.error}'),
          );
        }

        final allTables = snapshot.data ?? [];

        final tables = allTables
            .where((table) => table.section == widget.section)
            .toList();

        tables.sort(
          (a, b) => naturalSortCompare(a.tablename, b.tablename),
        );

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isLandScape ? 1.2 : 1.0,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: tables.length + 1,
          itemBuilder: (context, index) {
            if (index == tables.length) {
              return AdminAddTableCard(
                onTapFunc: () => _showAddTableDialog(context),
              );
            }

            final table = tables[index];

            return AdminTableCard(
              table: table,
              companyId: widget.companyId,
              userId: widget.userId,
              onChanged: _reloadTables,
            );
          },
        );
      },
    );
  }
}
