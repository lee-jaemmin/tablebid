import 'package:flutter/material.dart';
import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/services/item_api.dart';
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
        builder: (context) => Center(child: CircularProgressIndicator()),
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
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                    );
                  }).toList(),
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          Center(child: CircularProgressIndicator()),
                    );
                    if (_nameController.text.isEmpty ||
                        _priceController.text.isEmpty ||
                        _selectedCategoryId == null) {
                      if (!mounted) return;
                      Navigator.of(context).pop(); // 로딩원
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
                      sendMenuData();
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
