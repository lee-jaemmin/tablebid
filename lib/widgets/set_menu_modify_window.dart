import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/set_menu_model.dart';
import 'package:tablebid/screens/set_menu_create_screen.dart';
import 'package:tablebid/services/set_menu_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class SetMenuModifyWindow extends StatefulWidget {
  final String companyId;
  final Future<void> Function() loadData; // or AsyncCallback
  // VoidCallBack은 실행만 하고 끝나므로 await 대상이 아니므로 쓰면 x
  final SetMenuModel setMenu;
  const SetMenuModifyWindow({
    super.key,
    required this.companyId,
    required this.loadData,
    required this.setMenu,
  });

  @override
  State<SetMenuModifyWindow> createState() => _SetMenuModifyWindowState();
}

class _SetMenuModifyWindowState extends State<SetMenuModifyWindow> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  late bool _hasMixer;
  late String _components;
  bool _isLoading = true;
  List<SelectedComponents>? _selectedComponents;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.setMenu.setName;
    _priceController.text = NumberFormat(
      '#,###',
    ).format(widget.setMenu.setPrice);
    _hasMixer = widget.setMenu.hasMixer;
    loadData();
  }

  Future<void> loadData() async {
    try {
      final components = await SetMenuApi().getSetMenuItemsBySetMenu(
        setMenuId: widget.setMenu.id,
      );
      setState(() {
        _components = components;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
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
      await SetMenuApi().updateSetMenu(
        companyId: widget.companyId,
        setMenuId: widget.setMenu.id,
        setName: _nameController.text,
        setPrice: int.parse(_priceController.text.replaceAll(',', '')),
        isActive: true,
        hasMixer: _hasMixer,
        components: _selectedComponents
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
    return _isLoading
        ? Center(child: CupertinoActivityIndicator())
        : GestureDetector(
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
                                ? Icon(
                                    Icons.toggle_on,
                                    size: 48,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.toggle_off,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                          ),
                        ],
                      ),
                      InputDecorator(
                        decoration: InputDecoration(labelText: '구성품'),
                        child: Text(
                          (_selectedComponents == null || _selectedComponents!.isEmpty)
                          ? _components
                          : _selectedComponents!.map((component)=>'${component.itemName} ${component.quantity}'
                          ).join(', ')
                          ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF904E55),
                    side: BorderSide(
                      color: Color.fromARGB(255, 112, 10, 10),
                    ),
                        ),
                        onPressed: () async {
                          final newComponents = await Navigator.push<List<SelectedComponents>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetMenuCreateScreens(
                              companyId: widget.companyId,
                            ),
                          ),
                        );
                        if(!mounted && newComponents == null || newComponents!.isEmpty) return;
                        setState(() {
                          _selectedComponents = newComponents;
                          loadData();
                        });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('구성품 수정하기'),
                          ],
                        ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('메뉴 등록 중 에러 발생')),
                            );
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
