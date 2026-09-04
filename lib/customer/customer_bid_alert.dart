import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class CustomerBidAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;

  const CustomerBidAlert({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  State<CustomerBidAlert> createState() => _CustomerBidAlertState();
}

class _CustomerBidAlertState extends State<CustomerBidAlert> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _priceController;
  late final TextEditingController _timeController;
  late DateTime _selectedDateTime;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _priceController = TextEditingController(
      text: widget.table.leastBidPrice == null
          ? ''
          : formatPrice(widget.table.leastBidPrice!),
    );
    _timeController = TextEditingController();
    final now = DateTime.now();
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

  Future<void> _selectReservationTime() async {
    var temporaryDateTime = _selectedDateTime;
    FocusScope.of(context).unfocus();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: temporaryDateTime,
            use24hFormat: true,
            minuteInterval: 5,
            onDateTimeChanged: (newDateTime) {
              temporaryDateTime = newDateTime;
              setState(() {
                _selectedDateTime = newDateTime;
                _timeController.text =
                    '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _timeController.text.isEmpty ||
        _priceController.text.isEmpty) {
      setState(() {
        _errorText = '필수 정보를 모두 입력해주세요.';
      });
      return;
    }
    if (_isSubmitting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.userId) {
      setState(() {
        _errorText = '로그인 정보를 확인해주세요.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty)
        throw Exception('Firebase ID Token 없음');
      await ReservationApi().registerReservation(
        reservationTime: _selectedDateTime,
        tableId: widget.table.id,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        bidPrice: int.tryParse(_priceController.text.replaceAll(',', '')),
        idToken: token,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(content: Text('비딩 등록 성공: ${widget.table.tablename}')),
      );
    } catch (e) {
      if (e.toString().contains("Too many reservations")) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('최대 예약 개수는 3개입니다. 나머지 예약을 삭제하고 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _errorText = '비딩 등록 중 오류가 발생했습니다.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerProducts = widget.table.offerProducts?.trim() ?? '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.table.tablename} 비딩 참여'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (offerProducts.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('제공 품목: $offerProducts'),
                  ),
                  const SizedBox(height: 12),
                ],
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
                        if (phoneNumber.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: phoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('번호 복사 완료')),
                        );
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _selectReservationTime,
                  decoration: const InputDecoration(
                    labelText: '(필수) 예약 시간',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '비딩 제안가 (단위: 원)',
                  ),
                  inputFormatters: [PriceFormatters()],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CupertinoActivityIndicator(
                            color: Colors.black,
                          ),
                        )
                      : const Text('등록', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
