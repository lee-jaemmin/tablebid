import 'package:flutter/material.dart';
import 'package:tablebid/methods/cache_menu.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/screens/inactive_menu_screen.dart';
import 'package:tablebid/services/item_api.dart';
import 'package:tablebid/widgets/menu_modify_window.dart';
import 'package:tablebid/widgets/menu_window.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class MenuScreen extends StatefulWidget {
  final String companyId;
  const MenuScreen({super.key, required this.companyId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  int? _selectedCategoryId = 1;
  bool _isLoading = true;
  String? _errorMessage;

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
      final categories =
          menuCache.categories
              .where((category) => category.isActive == true)
              .toList()
            ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
      final items =
          menuCache.items.where((item) => item.isActive == true).toList()
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

  Future<void> modifyMenu(ItemModel item) async {
    if (item.isActive) {
      // 이제 끌거야.
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );
        await ItemApi().updateItem(itemId: item.id, isActive: false);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메뉴 비활성화: ${item.itemName}'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
        await _loadData(forceRefresh: true);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('아이템을 비활성화 시키는 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _items
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList(); // 현재 선택한 카테고리에 속한 메뉴
    return Scaffold(
      appBar: AppBar(
        title: Text('메뉴 관리'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MenuWindow(
                    companyId: widget.companyId,
                    categories: _categories,
                    loadData: _loadData,
                  ),
                );
              },
              icon: Icon(
                Icons.add,
                size: 30,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () async {
                final result = await showDialog<InactiveMenuResult>(
                  context: context,
                  builder: (context) => InactiveMenuScreen(
                    companyId: widget.companyId,
                  ),
                );
                if (result?.changed == true) {
                  await _loadData(forceRefresh: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text('메뉴 활성화: ${result?.itemName}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.lock,
                size: 30,
              ),
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
                SizedBox(child: Text('[토글] 메뉴 활성화/비활성화\n[길게 누르기] 메뉴 속성 수정.')),
                SizedBox(height: 10),
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
                        child: selectedItems.isEmpty
                            ? const Center(child: Text('등록된 메뉴가 없습니다.'))
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
                                            color: Colors.lightGreenAccent,
                                          )
                                        : const Icon(
                                            Icons.toggle_off,
                                            color: Colors.grey,
                                          ),
                                    onTap: () async {
                                      modifyMenu(item);
                                    },
                                    onLongPress: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) => MenuModifyWindow(
                                          companyId: widget.companyId,
                                          loadData: _loadData,
                                          item: item,
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
              ],
            ),
        ],
      ),
    );
  }
}
