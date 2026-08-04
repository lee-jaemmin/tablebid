import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_history_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/reregister_screen.dart';
import 'package:tablebid/services/history_api.dart';
import 'package:tablebid/services/table_history_purchase_api.dart';

class HistoryGridView extends StatelessWidget {
  final List<TableModel> tables;
  final String companyId;

  HistoryGridView({super.key, required this.tables, required this.companyId});

  @override
  Widget build(BuildContext context) {
    tables.sort((a, b)=>naturalSortCompare(a.tablename, b.tablename));
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final isTablet = size.shortestSide > 600;
    final isLandScape = orientation == Orientation.landscape;

    int crossAxisCount = isTablet
        ? (isLandScape ? 6 : 4)
        : (isLandScape ? 4 : 3);

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isLandScape ? 1.2 : 1.0,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _showHistoryBottomSheet(
          context,
          tables[index],
          tables[index].id,
        ),
        child: Card(
          color: Colors.white,
          child: Center(
            child: Text(
              tables[index].tablename,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(
    BuildContext context,
    TableModel table,
    String tableId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능하게 설정
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9, // 화면의 90% 채움
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${table.tablename} 히스토리',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<TableHistoryModel>>(
                future: HistoryApi().getHistoriesByTable(tableId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('테이블별 히스토리')),
                      body: Center(
                        child: Text('테이블별 히스토리 로딩 실패: ${snapshot.error}'),
                      ),
                    );
                  }

                  final histories = [...snapshot.data ?? []];
                  if (histories.isEmpty) {
                    return Center(child: Text('히스토리가 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: histories.length,
                    itemBuilder: (context, index) {
                      final history = histories[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            '손님: ${history.customerName} (${history.persons}명)',
                          ),
                          subtitle: FutureBuilder(
                            future: TableHistoryPurchaseApi().getHpByHistory(
                              history.id,
                            ),
                            builder: (context, snapshot) {
                              final purchases = snapshot.data ?? [];
                              final purchaseText = purchases.isEmpty
                                  ? '없음'
                                  : purchases
                                        .map((purchase) => purchase.itemName)
                                        .join(', ');
                              return Text(
                                '구매 목록: $purchaseText\n'
                                '전화 번호: ${history.customerPhone}\n'
                                '아웃 스태프: ${history.userName}\n'
                                '비고: ${history.remark}',
                              );
                            },
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReregisterScreen(
                                  companyId: companyId,
                                  historyData: history,
                                ),
                              ),
                            ),
                            child: const Text(
                              '재등록',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
