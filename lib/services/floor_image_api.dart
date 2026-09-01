import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
  Future<String> _getToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw const FloorImageApiException(401, '로그인이 필요합니다.');
    }
    return token;
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return '요청 처리 중 오류가 발생했습니다.';
  }

  Future<http.Response> _getFloorImageUrl(
    String companyId, {
    bool forceRefresh = false,
  }) async {
    final token = await _getToken(forceRefresh: forceRefresh);
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/floor-image-url',
    );
    return http.get(url, headers: {'Authorization': 'Bearer $token'});
  }

  Future<String> getFloorImageUrl(String companyId) async {
    var response = await _getFloorImageUrl(companyId);
    if (response.statusCode == 401) {
      response = await _getFloorImageUrl(companyId, forceRefresh: true);
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    }
    throw FloorImageApiException(response.statusCode, _errorMessage(response));
  }

  Future<http.Response> _uploadFloorImage({
    required String companyId,
    required List<int> bytes,
    required String filename,
    required String contentType,
    bool forceRefresh = false,
  }) async {
    final token = await _getToken(forceRefresh: forceRefresh);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/companies/$companyId/floor-image'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
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
