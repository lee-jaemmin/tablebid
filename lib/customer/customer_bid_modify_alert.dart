import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class CustomerBidModifyAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;
  final int reservationId;
  final DateTime? reservationTime;
  final String customerName;
  final String phonenumber;
  final int? bidPrice;
  final bool? isFixed;

  const CustomerBidModifyAlert({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
    required this.reservationId,
    required this.reservationTime,
    required this.customerName,
    required this.phonenumber,
    required this.bidPrice,
    required this.isFixed,
  });

  @override
  State<CustomerBidModifyAlert> createState() => _CustomerBidModifyAlertState();
}

class _CustomerBidModifyAlertState extends State<CustomerBidModifyAlert> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _priceController;
  late final TextEditingController _timeController;
  late DateTime _selectedDateTime;
  String? _errorText;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isFixed = false;

  Future<void> _loadUser() async {
    try {
      final user = await UserApi().getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _phoneController.text = formatKoreanPhoneNumber(user.phonenumber);
        _isLoading = false;
      });
    } catch (e) {
      print('유저 로딩 중 오류 발생: $e');
      if (!mounted) return;
      setState(() {
        _errorText = '유저 로딩 중 오류 발생';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerName);
    _phoneController = TextEditingController(text: widget.phonenumber);
    _priceController = TextEditingController(
      text: widget.bidPrice == null ? '' : formatPrice(widget.bidPrice!),
    );
    _timeController = TextEditingController();
    final now = DateTime.now();
    _selectedDateTime =
        widget.reservationTime ??
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          (now.minute / 5).round() * 5,
        );
    if (widget.reservationTime != null) {
      _timeController.text =
          '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}';
    }
    _isFixed = widget.isFixed ?? false;
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String formatKoreanPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return '';

    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('82')) {
      digits = '0${digits.substring(2)}';
    }

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-'
          '${digits.substring(3, 7)}-'
          '${digits.substring(7)}';
    }

    return value;
  }

  Future<void> _selectReservationTime() async {
    if(_isFixed) return;
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
      if (token == null || token.isEmpty) {
        throw Exception('Firebase ID Token 없음');
      }
      await ReservationApi().updateReservation(
        reservationId: widget.reservationId,
        reservationTime: _selectedDateTime,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        bidPrice: int.tryParse(_priceController.text.replaceAll(',', '')),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(content: Text('입찰 수정 성공: ${widget.table.tablename}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        print('예약 수정 중 오류: $e');
        _errorText = '입찰 수정 중 오류가 발생했습니다.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteReservation() async {
    final reservationTime = widget.reservationTime;
    if (reservationTime == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('예약 삭제 불가'),
          content: const Text('도착 예정 시간이 없어 예약을 삭제할 수 없습니다.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    final deleteDeadline = reservationTime.subtract(const Duration(hours: 2));
    if (!DateTime.now().isBefore(deleteDeadline)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('예약 삭제 불가'),
          content: const Text('도착 예정 시간 2시간 전부터는 예약을 삭제할 수 없습니다.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예약 삭제'),
        content: const Text('정말로 예약을 삭제하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    '아니요',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('예', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
      await ReservationApi().deleteReservation(
        reservationId: widget.reservationId,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(const SnackBar(content: Text('예약이 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = '예약 삭제 중 오류가 발생했습니다.';
      });
      print('예약 삭제 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerProducts = widget.table.offerProducts?.trim() ?? '';
    return _isLoading
        ? const CupertinoActivityIndicator()
        : AlertDialog(
            title: Text('${widget.table.tablename} 경매 수정'),
            content: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SizedBox(
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
                        readOnly: _isFixed,
                        decoration: const InputDecoration(
                          labelText: '(필수) 손님 이름',
                        ),
                      ),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneNumberFormatter()],
                        readOnly: _isFixed,
                        decoration: InputDecoration(
                          labelText: '(필수) 전화 번호',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              final phoneNumber = _phoneController.text;
                              if (phoneNumber.isEmpty) return;
                              Clipboard.setData(
                                ClipboardData(text: phoneNumber),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('번호 복사 완료')),
                              );
                            },
                          ),
                        ),
                      ),
                      TextField(
                        controller: _timeController,
                        readOnly: _isFixed,
                        onTap: _selectReservationTime,
                        decoration: const InputDecoration(
                          labelText: '(필수) 예약 시간',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),
                      TextField(
                        readOnly: _isFixed,
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '입찰가 (단위: 원)',
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
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _isSubmitting ? null : _deleteReservation,
                      child: const Text(
                        '삭제',
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
                          : const Text(
                              '수정',
                              style: TextStyle(color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}
