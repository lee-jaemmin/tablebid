import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatPrice(int price) {
  return '${NumberFormat('#,###').format(price)}원';
}

// 입력할 때 실시간으로 세 자리마다 콤마를 찍어주는 클래스
class PriceFormatters extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // 숫자 이외의 문자는 모두 제거 (방어 로직)
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return newValue.copyWith(text: '');

    // 숫자를 int로 바꾼 뒤 intl 패키지로 콤마 찍기
    int value = int.parse(numericOnly);
    String formatted = NumberFormat('#,###').format(value);

    // 콤마가 추가된 문자열을 반환하고, 커서를 맨 끝으로 이동
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}