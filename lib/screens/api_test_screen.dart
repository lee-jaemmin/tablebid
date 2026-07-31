import 'package:flutter/material.dart';
import 'package:tablebid/services/item_api.dart';
import 'package:tablebid/services/purchase_api.dart';
import '../services/table_api.dart';
import '../models/table_model.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestScreen> {
  List<TableModel> tables = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadTables() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await TableApi().getTables('111');

      setState(() {
        tables = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onPurchaseTap(String tableId) async {
    final purchases = await PurchaseApi().getPurchases(tableId);
    for (final purchase in purchases) {
      print(
        '${purchase.itemName} / ${purchase.quantity} / ${purchase.totalPrice}',
      );
    }
  }

  void _onPurchaseLongPress(String tableId) async {
    final purchase = await PurchaseApi().createPurchase(
      tableId: tableId,
      itemId: 1,
      quantity: 1,
    );
    print(
      '${purchase.itemName} / ${purchase.quantity} / ${purchase.totalPrice}',
    );
    final tables = await TableApi().getTables('111');
    for (final table in tables) {
      print('${table.id}의 총 가격: ${table.totalPrice}');
    }
  }

  void _onPurchaseDoubleTap(String tableId) async {
    final purchase = await PurchaseApi().tableOut(tableId: tableId);
    final tables = await TableApi().getTables('111');
    for (final table in tables) {
      print('${table.id}의 총 가격: ${table.totalPrice}');
    }
    print('${tableId}의 히스토리: ${purchase}');
  }

  Future<void> _showItemSelector(String tableId) async {
    final items = await ItemApi().getItems('111');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return ListTile(
              title: Text(item.itemName),
              subtitle: Text('${item.itemPrice}원'),
              onTap: () async {
                Navigator.pop(context);

                final purchase = await PurchaseApi().createPurchase(
                  tableId: tableId,
                  itemId: item.id,
                  quantity: 1,
                );

                print(
                  '${purchase.itemName} / ${purchase.quantity} / ${purchase.totalPrice}',
                );
                final tables = await TableApi().getTables('111');
                for (final table in tables) {
                  print('${table.id}의 총 가격: ${table.totalPrice}');
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: loadTables,
            child: const Text('테이블 다시 불러오기'),
          ),

          ElevatedButton(
            onPressed: () {
              _showItemSelector('t_B1');
            },
            child: const Text('구매하기'),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];

                return GestureDetector(
                  onTap: () => _onPurchaseTap(table.id),
                  onLongPress: () => _onPurchaseLongPress(table.id),
                  onDoubleTap: () => _onPurchaseDoubleTap(table.id),
                  child: ListTile(
                    title: Text(table.tablename),
                    subtitle: Text(
                      '${table.section} / ${table.status} / ${table.totalPrice}',
                    ),
                    trailing: Text(table.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
