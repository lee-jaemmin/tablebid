import 'package:flutter/material.dart';
import 'package:tablebid/methods/cache_menu.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/models/log_model.dart';
import 'package:tablebid/models/reservation_purchase_model.dart';
import 'package:tablebid/screens/edit_purchase_screen.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class SelectedItem {
  final int itemId;
  final String itemName;
  int quantity;
  final int unitPrice;

  SelectedItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });
}

class ReservationPurchaseScreen extends StatefulWidget {
  final String companyId;
  final String tableId;
  final String tableName;
  final String userId;
  const ReservationPurchaseScreen({
    super.key,
    required this.companyId,
    required this.tableId,
    required this.tableName,
    required this.userId,
  });

  @override
  State<ReservationPurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<ReservationPurchaseScreen> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  List<SelectedItem> _newPurchases = []; // 이번에 고르는 애들
  List<ReservationPurchaseModel> _existedPurchase = []; // 누적
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('userid: ${widget.userId}');
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cachedMenu = await CacheMenu.instance.load(
        widget.companyId,
        forceRefresh: forceRefresh,
      );

      final categories =
          cachedMenu.categories
              .where((category) => category.isActive == true)
              .toList()
            ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
      final items =
          cachedMenu.items.where((item) => item.isActive == true).toList()
            ..sort((a, b) => a.itemName.compareTo(b.itemName));

      setState(() {
        _categories = categories;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '메뉴 정보를 불러오지 못했습니다.';
        _isLoading = false;
      });
      print(e);
    }
  }

  Future<void> _addPurchase(ItemModel item) async {
    // 한 번 누를 때마다 실행.
    final selectedItem = SelectedItem(
      itemId: item.id,
      itemName: item.itemName,
      quantity: 1,
      unitPrice: item.itemPrice,
    );

    setState(() {
      final index = _newPurchases.indexWhere(
        (purchase) => purchase.itemId == selectedItem.itemId,
      ); // 있으면 그 인덱스, 없으면 -1 반환

      if (index == -1) {
        _newPurchases.add(selectedItem);
      } else {
        _newPurchases[index].quantity += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _items
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tableName} 구매내역'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push<List<LogModel>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditPurchaseScreen(tableId: widget.tableId),
                  ),
                );
              },
              child: Icon(Icons.edit),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else
            Column(
              children: [
                _PurchaseSummary(
                  existingPurchases: _existedPurchase,
                  newPurchases: _newPurchases,
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .5, // 기기의 반
                        child: ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                category.id == _selectedCategoryId;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: Colors.green.shade50,
                              title: Text(category.categoryName),
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                });
                              },
                            );
                          },
                        ),
                      ),

                      const VerticalDivider(width: 1),

                      Expanded(
                        child: selectedItems.isEmpty
                            ? const Center(child: Text('등록된 메뉴가 없습니다.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: selectedItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = selectedItems[index];
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    title: Text(item.itemName),
                                    subtitle: Text(formatPrice(item.itemPrice)),
                                    trailing: const Icon(Icons.add),
                                    onTap: () => _addPurchase(item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (!context.mounted) return;
              Navigator.pop(context, _newPurchases);
            },
            child: const Text(
              '구매 완료',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  final List<ReservationPurchaseModel> existingPurchases;
  final List<SelectedItem> newPurchases;
  const _PurchaseSummary({
    required this.existingPurchases,
    required this.newPurchases,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = existingPurchases.fold<int>(
      0,
      (sum, purchase) => sum + purchase.totalPrice,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('누적 구매 목록'),
                const SizedBox(height: 6),
                Text(
                  '총 가격: ${formatPrice(totalPrice)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (existingPurchases.isEmpty)
                  Text('아직 구매 내역이 없습니다.')
                else
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      itemCount: existingPurchases.length,
                      itemBuilder: (context, index) {
                        final purchase = existingPurchases[index];
                        return Text(
                          '${purchase.itemName} ${purchase.quantity} = '
                          '${formatPrice(purchase.unitPrice * purchase.quantity)}',
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 구매 목록'),
                const SizedBox(height: 6),
                if (newPurchases.isEmpty)
                  Text('아직 구매 내역이 없습니다.')
                else
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      itemCount: newPurchases.length,
                      itemBuilder: (context, index) {
                        final purchase = newPurchases[index];
                        return Text(
                          '${purchase.itemName} ${purchase.quantity} = '
                          '${formatPrice(purchase.unitPrice * purchase.quantity)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
