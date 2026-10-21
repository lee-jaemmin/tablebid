String toReservationServerPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^8210\d{8}$').hasMatch(digits)) return '+$digits';
  if (RegExp(r'^010\d{8}$').hasMatch(digits)) {
    return '+82${digits.substring(1)}';
  }
  throw const FormatException('휴대폰 번호는 010으로 시작하는 11자리여야 합니다.');
}

String toReservationDisplayPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final localDigits = RegExp(r'^8210\d{8}$').hasMatch(digits)
      ? '0${digits.substring(2)}'
      : digits;
  if (!RegExp(r'^010\d{8}$').hasMatch(localDigits)) return value;
  return '${localDigits.substring(0, 3)}-${localDigits.substring(3, 7)}-${localDigits.substring(7)}';
}
