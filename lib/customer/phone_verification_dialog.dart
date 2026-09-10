import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/widgets/phonenumber_formatter.dart';

class PhoneVerificationDialog extends StatefulWidget {
  const PhoneVerificationDialog();

  @override
  State<PhoneVerificationDialog> createState() =>
      _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId; // 인증번호 전송 절차가 시작됐는지 나타내는 임시값.
  String? _phoneNumber;
  String? _errorText;
  bool _isProcessing = false;
  bool _isCompleted = false;
  bool _codeSent = false;
  ConfirmationResult? _confirmationResult;

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
      await user.updatePhoneNumber(credential); // 번호 저장
      await user.reload();
      final verifiedUser = FirebaseAuth.instance.currentUser;
      final verifiedPhoneNumber = verifiedUser?.phoneNumber;
      if (verifiedPhoneNumber == null) {
        throw Exception('인증된 전화번호를 가져올 수 없습니다.');
      }
      print(verifiedPhoneNumber);
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

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorText = "6자리 인증 코드를 입력해주세요";
      });
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });
    try {
      if (kIsWeb) {
        final confirmationResult = _confirmationResult;
        if (confirmationResult == null) {
          throw Exception('먼저 인증번호를 전송해주세요.');
        }
        final credential = await confirmationResult.confirm(
          code,
        ); // 사용자 계정에 자동으로 폰 번호 저장 되므로 updatePhoneNumber호출 x
        final verifiedUser = credential.user;
        await verifiedUser?.reload();
        final verifiedPhoneNumber =
            FirebaseAuth.instance.currentUser?.phoneNumber;

        if (verifiedPhoneNumber == null) {
          throw Exception('인증된 전화번호를 가져올 수 없습니다.');
        }
        if(!mounted) return;
        Navigator.pop(context, verifiedPhoneNumber);
      } else {
        final verificationId = _verificationId;
        if (verificationId == null) {
          throw Exception('먼저 인증번호를 전송해주세요.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code,
        );
        await _completeVerification(credential, _phoneNumber!);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = e.code == 'invalid-verification-code'
            ? '인증번호가 올바르지 않습니다.'
            : '번호 인증에 실패했습니다: ${e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendCode() async {
    // 폰 번호 검사 후 정규화
    final phoneNumber = _normalizePhoneNumber(_phoneController.text.trim());
    _phoneNumber = phoneNumber;
    if (!RegExp(r'^\+82\d{9,10}$').hasMatch(phoneNumber)) {
      setState(() => _errorText = '휴대폰 번호를 정확히 입력해주세요.');
      return;
    }

    // 프로세스 시작
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      if (kIsWeb) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw FirebaseAuthException(code: 'user-not-found');
        }
        _confirmationResult = await user.linkWithPhoneNumber(phoneNumber);
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _errorText = null;
          _codeSent = true;
        });
      } else {
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
            print(">>>>>> 인증번호 실패: $e");
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _isProcessing = false;
              _errorText = null;
              _codeSent = true;
            });
          },
          codeAutoRetrievalTimeout: (verificationId) {
            if (!mounted) return;
            _verificationId = verificationId;
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorText = '인증번호 전송에 실패했습니다: ${e.code}';
      });
      print(">>>>>> 인증번호 실패: $e");
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
            enabled: !_codeSent && !_isProcessing,
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
            enabled: _codeSent && !_isProcessing,
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: _isProcessing
                    ? null
                    : _codeSent
                    ? _verifyCode
                    : _sendCode,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator(color: Colors.black),
                      )
                    : _codeSent
                    ? const Text('인증하기', style: TextStyle(color: Colors.black))
                    : const Text('전송하기', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
