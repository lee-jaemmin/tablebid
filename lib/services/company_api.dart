import 'dart:convert';
import 'package:tablebid/models/company_model.dart';
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

  Future<CompanyModel> createCompany({
    required String name,
    required String address,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies');
    final body = {
      'name': name,
      'address': address,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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

  Future<CompanyModel> updateCompany({
    required String companyId,
    String? name,
    String? region,
    List<String>? sections,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/$companyId');

    final body = {
      if (name != null) 'name': name,
      if (region != null) 'region': region,
      if (sections != null) 'sections': sections,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CompanyModel.fromJson(data);
    }
    throw Exception(
      'Failed to update Company : ${response.statusCode} ${response.body}',
    );
  }

  Future<CompanyModel> regenerateInviteCode({
    required String companyId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/regenerate-invite-code',
    );

    final response = await http.patch(
      url,
    );

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
}
