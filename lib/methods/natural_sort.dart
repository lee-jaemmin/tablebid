int naturalSortCompare(String a, String b) {
  // 숫자와 숫자가 아닌 부분을 분리하는 정규식
  final regExp = RegExp(r'([0-9]+)|([^0-9]+)');
  final matchesA = regExp.allMatches(a).toList();
  final matchesB = regExp.allMatches(b).toList();

  for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
    final groupA = matchesA[i].group(0)!;
    final groupB = matchesB[i].group(0)!;

    // 두 부분이 모두 숫자인 경우 숫자로 비교
    if (RegExp(r'^[0-9]+$').hasMatch(groupA) &&
        RegExp(r'^[0-9]+$').hasMatch(groupB)) {
      int numA = int.parse(groupA);
      int numB = int.parse(groupB);
      if (numA != numB) return numA.compareTo(numB);
    } else {
      // 숫자가 아닌 경우 문자열로 비교
      int res = groupA.compareTo(groupB);
      if (res != 0) return res;
    }
  }
  return a.length.compareTo(b.length);
}
