import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';

class PhoneVerificationDialog extends StatefulWidget {
  const PhoneVerificationDialog();

  @override
  State<PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  String? _phoneNumber;
  String? _errorText;
  bool _isProcessing = false;
  bool _isCompleted = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String value) {
    final normalized = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('010')) {
      return '+82${normalized.substring(1)}';
    }
    return normalized;
  }

  Future<void> _completeVerification(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    if (_isCompleted) return;
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw FirebaseAuthException(code: 'user-not-found');
      await user.updatePhoneNumber(credential);
      _isCompleted = true;
      if (!mounted) return;
      Navigator.pop(context, phoneNumber);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = e.code == 'invalid-verification-code'
            ? '인증번호가 올바르지 않습니다.'
            : '번호 인증에 실패했습니다: ${e.code}';
      });
    }
  }

  Future<void> _sendOrVerify() async {
    if (_verificationId != null) {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() => _errorText = '인증번호를 입력해주세요.');
        return;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _completeVerification(credential, _phoneNumber!);
      return;
    }

    final phoneNumber = _normalizePhoneNumber(_phoneController.text.trim());
    if (!RegExp(r'^\+82\d{9,10}$').hasMatch(phoneNumber)) {
      setState(() => _errorText = '휴대폰 번호를 정확히 입력해주세요.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });
    _phoneNumber = phoneNumber;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          await _completeVerification(credential, phoneNumber);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _errorText = '인증번호 전송에 실패했습니다: ${e.code}';
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isProcessing = false;
            _errorText = null;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = '인증번호 전송에 실패했습니다: ${e.code}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('번호 인증'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _phoneController,
            enabled: _verificationId == null && !_isProcessing,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '휴대폰 번호',
              hintText: '010-1234-5678',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            inputFormatters: [PhoneNumberFormatter()],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            enabled: _verificationId != null && !_isProcessing,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '인증번호',
              helperText: _verificationId == null
                  ? '전화 번호 입력 후 인증하기를 눌러주세요.'
                  : '6자리 인증번호 입력',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: _isProcessing ? null : _sendOrVerify,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator(
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        '인증하기',
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
