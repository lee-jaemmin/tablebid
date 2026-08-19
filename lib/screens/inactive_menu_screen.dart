import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/methods/cache_menu.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/models/set_menu_model.dart';
import 'package:tablebid/services/item_api.dart';
import 'package:tablebid/services/set_menu_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class InactiveMenuResult {
  final bool changed;
  final String itemName;

  const InactiveMenuResult({required this.changed, required this.itemName});
}

class InactiveMenuScreen extends StatefulWidget {
  final String companyId;
  const InactiveMenuScreen({super.key, required this.companyId});

  @override
  State<InactiveMenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<InactiveMenuScreen> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  int? _selectedCategoryId = 1;
  bool _isLoading = true;
  String? _errorMessage;
  List<SetMenuModel> _setMenus = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
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
          menuCache.items.where((item) => item.isActive == false).toList()
            ..sort((a, b) => a.itemName.compareTo(b.itemName));
      final setMenus = menuCache.setMenus
          .where((setMenu) => setMenu.isActive == false)
          .toList();
      setState(() {
        _categories = categories;
        _items = items;
        _setMenus = setMenus;
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

  Future<void> modifyMenu(ItemModel item) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CupertinoActivityIndicator()),
      );
      await ItemApi().updateItem(itemId: item.id, isActive: true);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(
        context,
        InactiveMenuResult(changed: true, itemName: item.itemName),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아이템을 활성화 시키는 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> modifySetMenu(SetMenuModel setMenu) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CupertinoActivityIndicator()),
      );
      await SetMenuApi().updateSetMenu(
        companyId: widget.companyId,
        setMenuId: setMenu.id,
        isActive: true,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(
        context,
        InactiveMenuResult(changed: true, itemName: setMenu.setName),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아이템을 활성화 시키는 중 오류가 발생했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _items
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList(); // 현재 선택한 카테고리에 속한 메뉴
    return Scaffold(
      appBar: AppBar(title: Text('비활성화 메뉴 관리')),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CupertinoActivityIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else
            Column(
              children: [
                SizedBox(child: Text('클릭: 메뉴 활성화/비활성화')),
                Divider(color: Colors.white),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .5,
                        child: ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                category.id == _selectedCategoryId;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: Color.fromARGB(
                                255,
                                112,
                                10,
                                10,
                              ),
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
                      const VerticalDivider(width: 1), // 세로 선
                      Expanded(
                        child: _selectedCategoryId == -1
                            ? _setMenus.isEmpty
                                  ? const Center(
                                      child: Text('해당 카테고리에\n비활성화된 메뉴가 없습니다.'),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.all(10),
                                      itemCount: _setMenus.length,
                                      separatorBuilder: (_, __) {
                                        return const SizedBox(height: 8);
                                      },
                                      itemBuilder: (context, index) {
                                        final setMenu = _setMenus[index];
                                        return ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          title: Text(setMenu.setName),
                                          subtitle: Text(
                                            formatPrice(setMenu.setPrice),
                                          ),
                                          trailing: setMenu.isActive
                                              ? const Icon(
                                                  Icons.toggle_on,
                                                  color: Colors.green,
                                                )
                                              : const Icon(
                                                  Icons.toggle_off,
                                                  color: Colors.grey,
                                                ),
                                          onTap: () async {
                                            modifySetMenu(setMenu);
                                          },
                                        );
                                      },
                                    )
                            : selectedItems.isEmpty
                            ? const Center(
                                child: Text('해당 카테고리에\n비활성화된 메뉴가 없습니다.'),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(10),
                                itemCount: selectedItems.length,
                                separatorBuilder: (_, __) {
                                  return const SizedBox(height: 8);
                                },
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
                                    trailing: item.isActive
                                        ? const Icon(
                                            Icons.toggle_on,
                                            color: Colors.green,
                                          )
                                        : const Icon(
                                            Icons.toggle_off,
                                            color: Colors.grey,
                                          ),
                                    onTap: () async {
                                      modifyMenu(item);
                                    },
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
    );
  }
}
