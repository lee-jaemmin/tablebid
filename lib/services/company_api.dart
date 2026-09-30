import 'dart:convert';
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/services/api_client.dart';
import 'package:http/http.dart' as http;

class CompanyApi {
  Future<CompanyModel> getCompany(String companyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/${companyId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final company = CompanyModel.fromJson(data);
      return company;
    }
    throw Exception(
      'Failed to get Company: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<CompanyModel>> getCompanies() async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CompanyModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Companies: ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> createCompany({
    required String name,
    required String address,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies');
    final body = {'name': name, 'address': address};

    final response = await http.post(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to create company: ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> modifySection({
    required String companyId,
    required String oldName,
    required String newName,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/modify-section',
    );

    final body = {'old_name': oldName, 'new_name': newName};

    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to update Section : ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> addSection({
    required String companyId,
    required String addedSection,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/add-section/$addedSection',
    );

    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to add section : ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> deleteSection({
    required String companyId,
    required String removedSection,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/remove-section/$removedSection',
    );

    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to remove section : ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> regenerateInviteCode({required String companyId}) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/regenerate-invite-code',
    );

    final response = await http.patch(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to regenerate invite code : ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> getCompanyByCode(String inviteCode) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/invite-code/${inviteCode}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to get Company by Code: ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> joinCompanyWithCode(String code) async {
    final url = Uri.parse('${ApiClient.baseUrl}/join-with-code');
    final body = {'code': code};
    final response = await http.post(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to join Company by Code: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> toggleTablesBid(String companyId, bool bidAvailable) async {
    final url = Uri.parse('${ApiClient.baseUrl}/toggle-tables-bid');
    final body = {'company_id': companyId, 'bid_available': bidAvailable};
    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw Exception(
      'Failed to toggle tables bid: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> setTablesBidEndAt(String companyId, DateTime bidEndAt) async {
    final url = Uri.parse('${ApiClient.baseUrl}/set-tables-bid-end-at');
    final body = {
      'company_id': companyId,
      'bid_end_at': bidEndAt.toUtc().toIso8601String(),
    };
    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return;
    }
    throw Exception(
      'Failed to set Bid End At: ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> uploadInsta(String companyId) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/upload-insta',
    );
    final response = await http.patch(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to upload insta: ${response.statusCode} ${response.body}',
    );
  }
}
