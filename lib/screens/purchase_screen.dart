import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/methods/cache_menu.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/models/log_model.dart';
import 'package:tablebid/models/set_menu_items_model.dart';
import 'package:tablebid/models/set_menu_model.dart';
import 'package:tablebid/models/table_purchases_model.dart';
import 'package:tablebid/screens/edit_purchase_screen.dart';
import 'package:tablebid/services/log_api.dart';
import 'package:tablebid/services/purchase_api.dart';
import 'package:tablebid/widgets/mixer_selection_bottom_sheet.dart';
import 'package:tablebid/widgets/price_formatter.dart';
import 'package:tablebid/widgets/purchase_item_chip.dart';

enum ProductType { item, setMenu }

class SelectedItem {
  final ProductType productType;
  final int itemId;
  final String itemName;
  int quantity;
  final int unitPrice;

  SelectedItem({
    required this.productType,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });
}

class PurchaseScreen extends StatefulWidget {
  final String companyId;
  final String tableId;
  final String tableName;
  final String userId;
  const PurchaseScreen({
    super.key,
    required this.companyId,
    required this.tableId,
    required this.tableName,
    required this.userId,
  });

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  List<SelectedItem> _newPurchases = []; // 이번에 고르는 애들
  List<LogModel> _logs = []; // 기존 구매 중 가장 최신
  List<TablePurchasesModel> _existedPurchase = []; // 누적
  List<SetMenuModel> _setMenus = [];
  List<SetMenuItemsModel> _setMenuItems = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;
  late TextEditingController _searchController;
  String _searchKeywords = '';
  @override
  void initState() {
    super.initState();
    print('구매 화면 userid: ${widget.userId}');
    _searchController = TextEditingController();
    _loadMenu();
    _loadPurchases(widget.tableId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final menuCache = await CacheMenu.instance.load(
        widget.companyId,
        forceRefresh: forceRefresh,
      );
      final categories = <CategoryModel>[
        CategoryModel(
          id: -1,
          categoryName: '세트 메뉴',
          sortOrder: 0,
          isActive: true,
        ),
        ...(menuCache.categories
            .where((category) => category.isActive == true)
            .toList()
          ..sort((a, b) => a.categoryName.compareTo(b.categoryName))),
      ];
      final items =
          menuCache.items.where((item) => item.isActive == true).toList()
            ..sort((a, b) => a.itemName.compareTo(b.itemName));
      final setMenus = menuCache.setMenus
          .where((setMenu) => setMenu.isActive == true)
          .toList();
      final setMenusItems = menuCache.setMenuItems.toList();
      setState(() {
        _categories = categories;
        _items = items;
        _setMenus = setMenus;
        _setMenuItems = setMenusItems;
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

  Future<void> _loadPurchases(String tableId) async {
    try {
      final purchases = await PurchaseApi().getPurchases(tableId);
      if (!mounted) return;
      setState(() {
        _existedPurchase = purchases;
      });
    } catch (e) {
      print("누적 구매 불러오는 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('누적 구매 불러오는 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 단품
  void _addPurchase(ItemModel item) {
    // 한 번 누를 때마다 실행.
    final selectedItem = SelectedItem(
      productType: ProductType.item,
      itemId: item.id,
      itemName: item.itemName,
      quantity: 1,
      unitPrice: item.itemPrice,
    );

    setState(() {
      final index = _newPurchases.indexWhere(
        (purchase) =>
            purchase.itemId == selectedItem.itemId &&
            purchase.productType == ProductType.item,
      ); // 있으면 그 인덱스, 없으면 -1 반환

      if (index == -1) {
        _newPurchases.add(selectedItem);
      } else {
        _newPurchases[index].quantity += 1;
      }
    });
  }

  // 세트
  void _addSetMenuPurchase(SetMenuModel setMenu) {
    // 한 번 누를 때마다 실행.
    final selectedItem = SelectedItem(
      productType: ProductType.setMenu,
      itemId: setMenu.id,
      itemName: setMenu.setName,
      quantity: 1,
      unitPrice: setMenu.setPrice,
    );

    setState(() {
      final index = _newPurchases.indexWhere(
        (purchase) =>
            purchase.itemId == selectedItem.itemId &&
            purchase.productType == ProductType.setMenu,
      ); // 있으면 그 인덱스, 없으면 -1 반환

      if (index == -1) {
        _newPurchases.add(selectedItem);
      } else {
        _newPurchases[index].quantity += 1;
      }
    });
  }

  Future<void> _showMixerSelectionBottomSheet() async {
    final selectedMixers = await showModalBottomSheet<List<ItemModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      builder: (context) => MixerSelectionBottomSheet(
        mixers: _items
            .where((item) => item.isActive && item.itemPrice == 0)
            .toList(),
      ),
    );
    if (!mounted || selectedMixers == null) return;
    for (final mixer in selectedMixers) {
      _addPurchase(mixer);
    }
  }

  Future<void> _sendData(List<SelectedItem> items) async {
    try {
      showDialog(
        context: context,
        builder: (context) => Center(child: CupertinoActivityIndicator()),
        barrierDismissible: false,
      );
      final batchId = DateTime.now().microsecondsSinceEpoch
          .toString(); // 플러터에서 batch id 생성
      await Future.wait(
        items.map((item) {
          if (item.productType == ProductType.item) {
            return LogApi().createLogAndPurchases(
              tableId: widget.tableId,
              itemId: item.itemId,
              quantity: item.quantity,
              userId: widget.userId,
              batchId: batchId,
            );
          } else {
            return LogApi().createLogAndPurchases(
              tableId: widget.tableId,
              setMenuId: item.itemId,
              quantity: item.quantity,
              userId: widget.userId,
              batchId: batchId,
            );
          }
        }),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      print("❌구매 전송 중 오류: $e");
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구매 데이터 전송 중 오류 발생')));
    }
  }

  Future<void> emptyNewPurchases() async {
    setState(() {
      _newPurchases.clear();
    });
    await _loadMenu();
  }

  @override
  Widget build(BuildContext context) {
    final isSetMenuSelected = _selectedCategoryId == -1;
    final visibleSetMenuItems = _setMenus.where((setMenu) {
      final keywords = _searchKeywords.trim().toLowerCase();
      final matchesSetMenu =
          isSetMenuSelected &&
          keywords.isNotEmpty &&
          setMenu.setName.toLowerCase().contains(keywords);
      return keywords.isEmpty || matchesSetMenu;
    }).toList();
    final categorySelectedItems = _items.where((item) {
      final keywords = _searchKeywords.trim().toLowerCase();
      final matchesCategory =
          (_selectedCategoryId == null ||
              item.categoryId == _selectedCategoryId) &&
          keywords.isEmpty;
      // (아무것도 안골랐거나(처음) 현재 고른 카테고리와 아이템 카테고리가 일치하고) 검색어가 없으면 true
      final matchesItem =
          keywords.isNotEmpty && item.itemName.toLowerCase().contains(keywords);
      // 검색어가 있고 이름이 일치하는 아이템이 있으면 true
      return item.isActive && (matchesItem || matchesCategory);
    }).toList()..sort((a, b) => a.itemName.compareTo(b.itemName));
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
                  logs: _logs,
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .35, // 기기의 반
                        child: ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                category.id == _selectedCategoryId;
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: Color.fromARGB(
                                  255,
                                  112,
                                  10,
                                  10,
                                ),
                                // 버건디
                                title: Text(category.categoryName),
                                onTap: () {
                                  // 현재 선택 카테고리
                                  setState(() {
                                    _selectedCategoryId = category.id;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const VerticalDivider(width: 1), // 세로선
                      Expanded(
                        child: isSetMenuSelected
                            ? visibleSetMenuItems.isEmpty
                                  ? const Center(child: Text('등록된 메뉴가 없습니다.'))
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(12),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: visibleSetMenuItems.map((
                                          setMenu,
                                        ) {
                                          final purchaseIndex = _newPurchases
                                              .indexWhere(
                                                (element) =>
                                                    element.itemId ==
                                                    setMenu.id,
                                              );
                                          final quantity = purchaseIndex == -1
                                              ? 0
                                              : _newPurchases[purchaseIndex]
                                                    .quantity;
                                          return PurchaseItemChip(
                                            itemName: setMenu.setName,
                                            isSelected: _newPurchases.any(
                                              (purchase) =>
                                                  purchase.itemId == setMenu.id,
                                            ),
                                            onTap: () async {
                                              _addSetMenuPurchase(setMenu);
                                              await _showMixerSelectionBottomSheet();
                                            },
                                            quantity: quantity,
                                          );
                                        }).toList(),
                                      ),
                                    )
                            : categorySelectedItems.isEmpty
                            ? const Center(child: Text('등록된 메뉴가 없습니다.'))
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categorySelectedItems.map((item) {
                                    final purchaseIndex = _newPurchases
                                        .indexWhere(
                                          (element) =>
                                              element.itemId == item.id,
                                        );
                                    final quantity = purchaseIndex == -1
                                        ? 0
                                        : _newPurchases[purchaseIndex].quantity;
                                    return PurchaseItemChip(
                                      itemName: item.itemName,
                                      isSelected: _newPurchases.any(
                                        (purchase) =>
                                            purchase.itemId == item.id,
                                      ),
                                      onTap: () async {
                                        _addPurchase(item);
                                        await _showMixerSelectionBottomSheet();
                                      },
                                      quantity: quantity,
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TapRegion(
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '메뉴 검색',
                        suffixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xffecb88d),
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchKeywords = value.trim();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await emptyNewPurchases();
                    if (!context.mounted) return;
                  },
                  child: const Text(
                    '초기화',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await _sendData(_newPurchases);
                    if (!context.mounted) return;
                    Navigator.pop(context, _newPurchases);
                  },
                  child: const Text(
                    '구매 완료',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  final List<TablePurchasesModel> existingPurchases;
  final List<SelectedItem> newPurchases;
  final List<LogModel> logs;
  const _PurchaseSummary({
    required this.existingPurchases,
    required this.newPurchases,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = existingPurchases.fold<int>(
      0,
      (sum, purchase) => sum + purchase.totalPrice,
    );

    final sortedLogs = [...logs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final latestLogs = sortedLogs.isEmpty
        ? <LogModel>[]
        : sortedLogs
              .where((log) => sortedLogs.first.batchId == log.batchId)
              .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).dialogTheme.backgroundColor,
      child: Row(
        children: [
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '누적 구매 목록',
          //         style: TextStyle(
          //           color: Color(0xffecb88d),
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       const SizedBox(height: 6),
          //       Text(
          //         '총 가격: ${formatPrice(totalPrice)}',
          //         style: TextStyle(fontWeight: FontWeight.bold),
          //       ),
          //       if (existingPurchases.isEmpty)
          //         SizedBox(height: 100, child: Text('아직 구매 내역이 없습니다.'))
          //       else
          //         SizedBox(
          //           height: 100,
          //           child: ListView.builder(
          //             itemCount: existingPurchases.length,
          //             itemBuilder: (context, index) {
          //               final purchase = existingPurchases[index];
          //               return Text(
          //                 '${purchase.itemName} ${purchase.quantity} = '
          //                 '${formatPrice(purchase.unitPrice * purchase.quantity)}',
          //               );
          //             },
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
          // const VerticalDivider(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이번 구매 목록',
                  style: TextStyle(
                    color: Color(0xffecb88d),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (newPurchases.isEmpty)
                  latestLogs.isEmpty
                      ? SizedBox(height: 50, child: Text('아직 구매 내역이 없습니다.'))
                      : SizedBox(
                          height: 50,
                          child: ListView.builder(
                            itemCount: latestLogs.length,
                            itemBuilder: (context, index) {
                              final log = latestLogs[index];
                              return Text(
                                '${log.itemName} ${log.quantity} = '
                                '${formatPrice(log.unitPrice * log.quantity)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        )
                else
                  SizedBox(
                    height: 50,
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
