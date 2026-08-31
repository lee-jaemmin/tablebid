import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/screens/set_menu_create_screen.dart';
import 'package:tablebid/services/item_api.dart';
import 'package:tablebid/services/set_menu_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class MenuWindow extends StatefulWidget {
  final String companyId;
  final List<CategoryModel> categories;
  final Future<void> Function() loadData; // or AsyncCallback
  // VoidCallBack은 실행만 하고 끝나므로 await 대상이 아니므로 쓰면 x
  const MenuWindow({
    super.key,
    required this.companyId,
    required this.categories,
    required this.loadData,
  });

  @override
  State<MenuWindow> createState() => _ReservationAlertState();
}

class _ReservationAlertState extends State<MenuWindow> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  int? _selectedCategoryId;
  bool _hasMixer = true;
  List<SelectedComponents> _selectedComponents = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> sendMenuData() async {
    print('MenuName: ${_nameController.text}');
    try {
      showDialog(
        context: context,
        builder: (context) => Center(child: CupertinoActivityIndicator()),
        barrierDismissible: false,
      );

      await ItemApi().createItem(
        itemName: _nameController.text,
        itemPrice: int.parse(_priceController.text.replaceAll(',', '')),
        categoryId: _selectedCategoryId!,
        companyId: widget.companyId,
        isActive: true,
      );
      if (!mounted) return;
      Navigator.pop(context); //윈도우 끄기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 등록 성공: ${_nameController.text}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context); //윈도우 끄기
      await widget.loadData();
    } catch (e) {
      print('❌ 메뉴 정보 전송 중 오류 발생');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 정보 전송 중 오류 발생'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> sendSetMenuData(
    List<SelectedComponents> selectedComponents,
  ) async {
    print('MenuName: ${_nameController.text}');
    try {
      showDialog(
        context: context,
        builder: (context) => Center(child: CupertinoActivityIndicator()),
        barrierDismissible: false,
      );

      await SetMenuApi().createSetMenu(
        setName: _nameController.text,
        setPrice: int.parse(_priceController.text.replaceAll(',', '')),
        companyId: widget.companyId,
        isActive: true,
        hasMixer: _hasMixer,
        components: selectedComponents,
      );
      if (!mounted) return;
      Navigator.pop(context); //윈도우 끄기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 등록 성공: ${_nameController.text}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context); //윈도우 끄기
      await widget.loadData();
    } catch (e) {
      print('❌ 메뉴 정보 전송 중 오류 발생');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 정보 전송 중 오류 발생'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('메뉴 추가'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '메뉴 이름'),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceFormatters()],
                  decoration: const InputDecoration(labelText: '가격'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('믹서 여부', style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _hasMixer = !_hasMixer;
                        });
                      },
                      child: _hasMixer
                          ? Icon(Icons.toggle_on, size: 48, color: Colors.green)
                          : Icon(
                              Icons.toggle_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.categories.map((category) {
                    final isSelected = category.id == _selectedCategoryId;
                    return ChoiceChip(
                      selectedColor: Color(0xffecb88d),
                      label: Text(category.categoryName),
                      selected: isSelected,
                      onSelected: (_) async {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                        if (_selectedCategoryId == -1) {
                          final selectedComponents = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetMenuCreateScreens(
                                companyId: widget.companyId,
                              ),
                            ),
                          );
                          if (!mounted || selectedComponents == null) return;
                          setState(() {
                            _selectedComponents = selectedComponents;  
                          });
                          
                        }
                      },
                    );
                  }).toList(),
                ),
                _selectedComponents.isNotEmpty
                    ? InputDecorator(
                        decoration: InputDecoration(labelText: '구성품'),
                        child: Text(
                          _selectedComponents
                              .map(
                                (component) =>
                                    ('${component.itemName} ${component.quantity}'),
                              )
                              .join(', '),
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
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
                    if (_nameController.text.isEmpty ||
                        _priceController.text.isEmpty ||
                        _selectedCategoryId == null) {
                      if (!mounted) return;
                      Navigator.of(context).pop(); // 팝업
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('정보를 모두 입력해주세요.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    try {
                      if (_selectedCategoryId == -1) {
                        if (_selectedComponents.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('세트 구성품을 선택해주세요.')),
                          );
                        }
                        await sendSetMenuData(_selectedComponents);
                      } else {
                        await sendMenuData();
                      }
                    } catch (e) {
                      print('❌ 메뉴 등록 중 에러 발생: $e');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('메뉴 등록 중 에러 발생')));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '등록',
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
