import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/reservation_purchase_screen.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class ReservationAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;

  const ReservationAlert({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  State<ReservationAlert> createState() => _ReservationAlertState();
}

class _ReservationAlertState extends State<ReservationAlert> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _priceController;

  // 예약 시간용 컨트롤러 및 변수 추가
  late TextEditingController _timeController;
  late DateTime _selectedDateTime;
  List<SelectedItem>? _selectedItems;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _priceController = TextEditingController();

    // 시간 초기화 로직
    _timeController = TextEditingController();
    DateTime now = DateTime.now();
    _selectedDateTime = now;

    _selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute / 5).round() * 5,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // 하단에서 올라오는 쿠퍼티노 타임 피커
  Future<void> _selectReservationTime(BuildContext context) async {
    DateTime tempDateTime = _selectedDateTime;
    FocusScope.of(context).unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: tempDateTime,
              use24hFormat: true,
              minuteInterval: 5,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  tempDateTime = newDateTime;
                  _selectedDateTime = tempDateTime;
                  _timeController.text =
                      "${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}";
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> sendReservationData() async {
    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      await ReservationApi().registerReservation(
        reservationTime: _selectedDateTime,
        tableId: widget.table.id,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        items: _selectedItems,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('예약 등록 성공: ${widget.table.tablename}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ 예약 등록 중 오류 발생');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 등록 중 오류 발생')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.table.tablename} 예약 등록'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _timeController,
                  readOnly: true, // 키보드 안 올라오게 막기
                  onTap: () => _selectReservationTime(context),
                  decoration: const InputDecoration(
                    labelText: '(필수) 예약 시간',
                    suffixIcon: Icon(Icons.access_time), // 시계 아이콘 추가
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '(필수) 손님 이름'),
                ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
                  decoration: InputDecoration(
                    labelText: '(필수) 손님 번호',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        final phoneNumber = _phoneController.text;
                        if (phoneNumber.isNotEmpty) {
                          Clipboard.setData(
                            ClipboardData(text: phoneNumber),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('번호 복사 완료'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceFormatters()],
                  decoration: const InputDecoration(labelText: '예약 금액'),
                  readOnly: true,
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    _selectedItems = await Navigator.push<List<SelectedItem>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationPurchaseScreen(
                          companyId: widget.companyId,
                          tableId: widget.table.id,
                          tableName: widget.table.tablename,
                          userId: widget.userId,
                        ),
                      ),
                    );
                    if (_selectedItems!.isEmpty) return;
                    int price = 0;
                    for (final item in _selectedItems!) {
                      price += item.unitPrice * item.quantity;
                    }
                    setState(() {
                      _priceController.text = formatPrice(price);
                    });
                    // infowindow의 경우 총 가격 다시 불러오는 코드는 별도의 함수에 있었지만
                    // 여기서는 그냥 이 부분에 작성.
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('구매내역 입력'),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: Text(_errorText!),
                  ),
                ],
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
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(10),
                    ),
                  ),

                  onPressed: () async {
                    if (_nameController.text.isEmpty ||
                        _phoneController.text.isEmpty ||
                        _timeController.text.isEmpty) {
                      setState(() {
                        _errorText = "필수 정보를 모두 입력해주세요.";
                      });
                      return;
                    }
                    if (_isSubmitting) return;
                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      await sendReservationData();                      
                    } catch (e) {
                      print('❌ 예약 등록 중 에러 발생: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('예약 등록 중 에러 발생')));
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '등록',
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
  }
}
