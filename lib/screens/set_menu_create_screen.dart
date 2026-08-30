import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/methods/cache_menu.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/widgets/purchase_item_chip.dart';

class SelectedComponents {
  final int itemId;
  final String itemName;
  int quantity;

  SelectedComponents({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });
}

class SetMenuCreateScreens extends StatefulWidget {
  final String companyId;

  const SetMenuCreateScreens({
    super.key,
    required this.companyId,
  });

  @override
  State<SetMenuCreateScreens> createState() => _SetMenuCreateScreenState();
}

class _SetMenuCreateScreenState extends State<SetMenuCreateScreens> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  List<SelectedComponents> _selectedComponents = []; // 이번에 고르는 세트 구성품
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;
  late TextEditingController _searchController;
  String _searchKeywords = '';
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMenu();
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

  // 구성품 선택
  void _addComponent(ItemModel item) {
    // 한 번 누를 때마다 실행.
    final selectedItem = SelectedComponents(
      itemId: item.id,
      itemName: item.itemName,
      quantity: 1,
    );

    setState(() {
      final index = _selectedComponents.indexWhere(
        (component) => component.itemId == selectedItem.itemId,
      ); // 있으면 그 인덱스, 없으면 -1 반환

      if (index == -1) {
        _selectedComponents.add(selectedItem);
      } else {
        _selectedComponents[index].quantity += 1;
      }
    });
  }

  void emptyComponents() {
    setState(() {
      _selectedComponents.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    final keywords = _searchKeywords.trim().toLowerCase();
    final matchedItems = _items
        .where((item) => item.itemName.toLowerCase().contains(keywords))
        .toList();
    final categorySelectedItems =
        _items.where((item) => item.categoryId == _selectedCategoryId).toList()
          ..sort((a, b) => a.itemName.compareTo(b.itemName));
    return Scaffold(
      appBar: AppBar(
        title: Text('세트 메뉴 생성'),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CupertinoActivityIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else
            Column(
              children: [
                _ComponentSummary(components: _selectedComponents),
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
                        child: _searchController.text.isNotEmpty
                            ? matchedItems.isEmpty
                                  ? Center(child: Text('검색된 상품이 없습니다.'))
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: matchedItems.map((item) {
                                        final componentIndex =
                                            _selectedComponents.indexWhere(
                                              (element) =>
                                                  element.itemId == item.id,
                                            );
                                        final quantity = componentIndex == -1
                                            ? 0
                                            : _selectedComponents[componentIndex]
                                                  .quantity;
                                        return PurchaseItemChip(
                                          itemName: item.itemName,
                                          isSelected: _selectedComponents.any(
                                            (component) =>
                                                component.itemId == item.id,
                                          ),
                                          onTap: () async {
                                            _addComponent(item);
                                          },
                                          quantity: quantity,
                                        );
                                      }).toList(),
                                    )
                            // 검색어 없음.
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categorySelectedItems.map((item) {
                                    final componentIndex = _selectedComponents
                                        .indexWhere(
                                          (element) =>
                                              element.itemId == item.id,
                                        );
                                    final quantity = componentIndex == -1
                                        ? 0
                                        : _selectedComponents[componentIndex]
                                              .quantity;
                                    return PurchaseItemChip(
                                      itemName: item.itemName,
                                      isSelected: _selectedComponents.any(
                                        (component) =>
                                            component.itemId == item.id,
                                      ),
                                      onTap: () async {
                                        _addComponent(item);
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
                  onPressed: () {
                    emptyComponents();
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
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.pop(context, _selectedComponents);
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

class _ComponentSummary extends StatelessWidget {
  final List<SelectedComponents> components;
  const _ComponentSummary({required this.components});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).dialogTheme.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선택 구성품 목록',
                  style: TextStyle(
                    color: Color(0xffecb88d),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                components.isEmpty
                    ? SizedBox(height: 50, child: Text('선택된 세트 메뉴 구성품이 없습니다.'))
                    : SizedBox(
                        height: 50,
                        child: ListView.builder(
                          itemCount: components.length,
                          itemBuilder: (context, index) {
                            final cmpnt = components[index];
                            return Text(
                              '${cmpnt.itemName} ${cmpnt.quantity}개',
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
