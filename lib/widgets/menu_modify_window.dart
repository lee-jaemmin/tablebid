import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/services/item_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class MenuModifyWindow extends StatefulWidget {
  final String companyId;
  final Future<void> Function() loadData; // or AsyncCallback
  // VoidCallBack은 실행만 하고 끝나므로 await 대상이 아니므로 쓰면 x
  final ItemModel item;
  const MenuModifyWindow({
    super.key,
    required this.companyId,
    required this.loadData,
    required this.item,
  });

  @override
  State<MenuModifyWindow> createState() => _ReservationAlertState();
}

class _ReservationAlertState extends State<MenuModifyWindow> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item.itemName;
    _priceController.text = NumberFormat('#,###').format(widget.item.itemPrice);
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
      await ItemApi().updateItem(
        itemId: widget.item.id,
        itemName: _nameController.text,
        itemPrice: int.parse(_priceController.text.replaceAll(',', '')),
        isActive: true,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 수정 성공: ${_nameController.text}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context); //윈도우 끄기
      await widget.loadData();
    } catch (e) {
      print('❌ 메뉴 정보 수정 중 오류 발생 $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴 수정 중 오류 발생'),
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
        title: Text('메뉴 수정'),
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
                  decoration: const InputDecoration(labelText: '가격 (원)'),
                ),
                SizedBox(height: 10),
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
                    showDialog(
                      context: context,
                      builder: (context) =>
                          Center(child: CupertinoActivityIndicator()),
                    );
                    if (_nameController.text.isEmpty ||
                        _priceController.text.isEmpty) {
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
                    '수정',
                    style: TextStyle(color: Colors.black),
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
