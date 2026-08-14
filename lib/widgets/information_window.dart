import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/move_screen.dart';
import 'package:tablebid/screens/purchase_screen.dart';
import 'package:tablebid/services/history_api.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class InformationWindow extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;
  final String userName;

  const InformationWindow({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
    required this.userName,
  });

  @override
  State<InformationWindow> createState() => _InformationWindowState();
}

class _InformationWindowState extends State<InformationWindow> {
  late TextEditingController _customerController;
  late TextEditingController _phoneController;
  late TextEditingController _personsController;
  late TextEditingController _remarksController;
  late TextEditingController _totalPriceController;
  late TextEditingController _userController;
  late List<String> _purchaseList;
  bool noPurchase = true;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: widget.table.customer);
    _phoneController = TextEditingController(text: widget.table.phonenumber);
    _personsController = TextEditingController(
      text: widget.table.persons == 0 ? '' : widget.table.persons.toString(),
    );
    _remarksController = TextEditingController(text: widget.table.remark);
    _totalPriceController = TextEditingController(
      text: formatPrice(widget.table.totalPrice),
    );
    _userController = TextEditingController(
      text: (widget.table.userName == "" || widget.table.userName == "이름 미지정")
          ? widget.userName
          : widget.table.userName,
    );
    _purchaseList = widget.table.purchaseSummary ?? [];
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _personsController.dispose();
    _remarksController.dispose();
    _totalPriceController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _registerTable() async {
    if (widget.table.status != 'inuse' &&
        _customerController.text.isEmpty &&
        _phoneController.text.isEmpty &&
        _remarksController.text.isEmpty &&
        _personsController.text.isEmpty &&
        noPurchase) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('정보를 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CupertinoActivityIndicator()),
    );
    try {
      final sendRegisterTime = widget.table.status == "available";
      await TableApi().updateTable(
        tableId: widget.table.id,
        userId: widget.userId,
        status: 'inuse',
        customer: _customerController.text.trim(),
        phonenumber: _phoneController.text.trim(),
        persons: int.tryParse(_personsController.text.trim()) ?? 0,
        remark: _remarksController.text.trim(),
        userName: _userController.text.trim(),
        registeredAt: sendRegisterTime ? DateTime.now() : null,
      );

      if (!mounted) return;
      navigator.pop();
      navigator.pop();
    } catch (e) {
      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('정보 등록 실패'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print(e);
    }
  }

  Future<void> _outTable() async {
    if (widget.table.status != 'inuse') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('빈 테이블을 아웃 시킬 수 없습니다. 손님을 먼저 등록해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아웃 확인'),
        content: Text('${widget.table.tablename} 테이블을 아웃 처리하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    '아웃 확정',
                    style: TextStyle(
                      color: Colors.white,
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

    if (confirmOut != true) return;
    showDialog(
      context: context,
      builder: (context) => Center(child: CupertinoActivityIndicator()),
      barrierDismissible: false,
    );
    await HistoryApi().tableOutAndCreateHistory(tableId: widget.table.id);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<void> _openPurchaseScreen() async {
    final selectedItems = await Navigator.push<List<SelectedItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseScreen(
          companyId: widget.companyId,
          tableId: widget.table.id,
          tableName: widget.table.tablename,
          userId: widget.userId,
        ),
      ),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      noPurchase = false;
    }
    try {
      final table = await TableApi().getTable(widget.table.id);
      if (!mounted) return;
      setState(() {
        _totalPriceController.text = formatPrice(table.totalPrice);
        _purchaseList = table.purchaseSummary ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구매 내역을 새로고침하지 못했습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCupertinoTimerPicker(BuildContext context) async {
    if (widget.table.status != 'inuse') {
      if (mounted) Navigator.pop(context); // info_alert 내리기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용 중인 테이블만 타이머를 설정할 수 있습니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 00:00 시작
    Duration selectedDuration = Duration.zero;

    // await => 빈 공간을 터치해 팝업을 닫을 때까지 기다림
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300, // 상단바가 빠졌으니 높이를 살짝 줄임
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm, // mm:ss
              minuteInterval: 5,
              initialTimerDuration: Duration.zero, // 00:00 세팅
              onTimerDurationChanged: (Duration newDuration) {
                // 룰렛을 굴릴 때마다 변수에 저장만
                selectedDuration = newDuration;
              },
            ),
          ),
        );
      },
    );

    // 팝업이 닫히면 서버로 전송
    if (selectedDuration.inSeconds > 0) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CupertinoActivityIndicator()),
      );
      // 타이머 db로 보내기
      await TableApi().updateTable(
        tableId: widget.table.id,
        userId: widget.userId,
        timerStartedAt: DateTime.now(),
        timerEndAt: DateTime.now().add(selectedDuration),
      );

      navigator.pop(); // 로딩창 끄기
      navigator.pop(); // info 내리기
      messenger.showSnackBar(
        SnackBar(
          content: Text("타이머 설정이 완료되었습니다."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 타이머 해제
  void _showCancelTimerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('타이머 해제'),
        content: const Text('타이머를 해제하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext), // 아니오: 그냥 창 닫기
                  child: const Text(
                    '아니오',
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
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    Navigator.pop(dialogContext); // 해제하시겠습니까? 창 닫기

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CupertinoActivityIndicator()),
                    );

                    await TableApi().updateTable(
                      tableId: widget.table.id,
                      userId: widget.userId,
                      clearTimer: true,
                    );

                    navigator.pop(); // 로딩창 끄기
                    navigator.pop(); // info 내리기
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("타이머가 해제되었습니다."),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('예', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('${widget.table.tablename} 정보 등록')),
            InkWell(
              onTap: widget.table.timerStartedAt == null
                  ? () => _showCupertinoTimerPicker(context)
                  : () => _showCancelTimerDialog(),
              child: widget.table.timerStartedAt == null
                  ? Icon(Icons.timer)
                  : Icon(Icons.timer_off),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: '손님 이름'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: '전화 번호',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        final phoneNumber = _phoneController.text;

                        if (phoneNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('복사할 번호가 없습니다.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Clipboard.setData(ClipboardData(text: phoneNumber));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('번호 복사 완료')),
                        );
                      },
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
                ),
                for (
                  var i = 0;
                  i < _purchaseList.length && _purchaseList.length != 0;
                  i++
                )
                  InputDecorator(
                    decoration: InputDecoration(labelText: '구매목록 ${i + 1}'),
                    child: Text(
                      "${_purchaseList[i]}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                TextField(
                  controller: _totalPriceController,
                  decoration: const InputDecoration(labelText: '총 가격'),
                  readOnly: true,
                ),
                TextField(
                  controller: _personsController,
                  decoration: const InputDecoration(labelText: '인원'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: '스태프'),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                TextField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: '비고'),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _openPurchaseScreen,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('구매내역 입력'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _outTable,
                  child: const Text('아웃', style: TextStyle(color: Colors.red)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    if (widget.table.status != 'inuse') {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('빈 테이블을 이동할 수 없습니다.\n먼저 정보를 입력해주세요'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoveScreen(
                          companyId: widget.companyId,
                          fromTable: widget.table,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '이동',
                    style: TextStyle(color: Colors.lightBlue),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _registerTable,
                  child: const Text(
                    '등록',
                    style: TextStyle(color: Color(0xffecb88d)),
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
