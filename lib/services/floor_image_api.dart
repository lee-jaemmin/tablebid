import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/api_client.dart';

class FloorImageApiException implements Exception {
  final int statusCode;
  final String message;

  const FloorImageApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class FloorImageApi {
  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return '요청 처리 중 오류가 발생했습니다.';
  }

  // http 형식 반환하는 함수
  Future<http.Response> _getFloorImageUrl(
    String companyId, {
    bool forceRefresh = false,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/floor-image-url',
    );
    return http.get(
      url,
      headers: await firebaseAuthHeaders(forceRefresh: forceRefresh),
    );
  }

  Future<String> getFloorImageUrl(String companyId) async {
    var response = await _getFloorImageUrl(companyId);
    if (response.statusCode == 401) {
      // 권한 없으면 다시 시도 -> 안되면 에러
      response = await _getFloorImageUrl(companyId, forceRefresh: true);
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String; // 최종 url 추출
    }
    throw FloorImageApiException(response.statusCode, _errorMessage(response));
  }

  // http 형식 반환 함수
  Future<http.Response> _uploadFloorImage({
    required String companyId,
    required List<int> bytes,
    required String filename,
    required String contentType,
    bool forceRefresh = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/companies/$companyId/floor-image'),
    );
    request.headers.addAll(await firebaseAuthHeaders(
      forceRefresh: forceRefresh,
      includeContentType: false,
    )); // 보안 인증 헤더 추가
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    ); // 이미지 바이트를 요청에 추가
    return http.Response.fromStream(await request.send());
  }


  Future<CompanyModel> uploadFloorImage({
    required String companyId,
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    var response = await _uploadFloorImage(
      companyId: companyId,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    if (response.statusCode == 401) {
      response = await _uploadFloorImage(
        companyId: companyId,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        forceRefresh: true,
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CompanyModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw FloorImageApiException(response.statusCode, _errorMessage(response));
  }
}
