import 'dart:convert';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/services/api_client.dart';
import 'package:http/http.dart' as http;

class UserApi {
  Future<UserModel> getUser(String userId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to get a User: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<UserModel>> getUsersByCompnay(String companyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/$companyId/users');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((elem) => UserModel.fromJson(elem)).toList();
    }
    throw Exception(
      'Failed to get a Users by Company: ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> updateUser({
    required String userId,
    String? userName,
    String? email,
    String? role,
    String? fcmToken,
    List<String>? cardfields,
    String? companyId,
    bool? isPushOn,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId');

    final body = {
      if (userName != null) 'username': userName,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (fcmToken != null) 'fcmtoken': fcmToken,
      if (cardfields != null) 'tablecardfields': cardfields,
      if (companyId != null) 'company_id': companyId,
      if (isPushOn != null) 'is_push_on': isPushOn,
    };

    final response = await http.patch(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to update User : ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> createUser({
    required String userId,
    required String userName,
    required String email,
    required String role,
    required String? fcmtoken,
    required List<String> cardFields,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users');
    final body = {
      'id': userId,
      'username': userName,
      'email': email,
      'role': role,
      'fcmtoken': fcmtoken,
      'tablecardfields': cardFields,
    };
    final response = await http.post(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to create User: ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> removeUserFromCompany({
    required String userId,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiClient.baseUrl}/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'company_id': null,
        'role': 'user',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove user from company: ${response.body}');
    }

    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteUser({
    required String userId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception(
      'Failed to delete User: ${response.statusCode} ${response.body}',
    );
  }
}
