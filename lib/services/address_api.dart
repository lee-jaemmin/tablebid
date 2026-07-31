import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressApi {
  static const _confmKey = String.fromEnvironment('JUSO_CONFM_KEY');
  Future<List<AddressResult>> getAddress(String keyword) async {
    final uri = Uri.https(
      'business.juso.go.kr',
      '/addrlink/addrLinkApi.do',
      {
        'confmKey': _confmKey,
        'currentPage': '1',
        'countPerPage': '10',
        'keyword': keyword,
        'resultType': 'json',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as Map<String, dynamic>?;
      final common = results?['common'] as Map<String, dynamic>?;
      final errorCode = common?['errorCode']?.toString();

      if (errorCode != null && errorCode != '0') {
        throw Exception(common?['errorMessage'] ?? '주소 검색에 실패했습니다.');
      }

      final juso = results?['juso'];
      if (juso is! List) return [];

      return juso
          .map((item) => AddressResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('주소 검색 실패: ${response.statusCode}');
  }
}

class AddressResult {
  final String roadAddr;
  final String jibunAddr;
  final String zipNo;
  final String bdMgtSn;

  AddressResult({
    required this.roadAddr,
    required this.jibunAddr,
    required this.zipNo,
    required this.bdMgtSn,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json) {
    return AddressResult(
      roadAddr: json['roadAddr'] ?? '',
      jibunAddr: json['jibunAddr'] ?? '',
      zipNo: json['zipNo'] ?? '',
      bdMgtSn: json['bdMgtSn'] ?? '',
    );
  }
}
