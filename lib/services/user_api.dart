import 'dart:convert';
import 'package:tablebid/methods/firebase_auth.dart';
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
    String? phonenumber,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId');
    print('>>>>> fucking role: $role');
    final body = {
      if (userName != null) 'username': userName,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (fcmToken != null) 'fcmtoken': fcmToken,
      if (cardfields != null) 'tablecardfields': cardfields,
      if (companyId != null) 'company_id': companyId,
      if (isPushOn != null) 'is_push_on': isPushOn,
      if (phonenumber != null) 'phonenumber': phonenumber,
    };

    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print(data);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to update User : ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> ensureUser({
    required String userName,
    required String email,
    required String? fcmtoken,
    required List<String> cardFields,
    String? signupRef,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/me');
    final body = {
      'username': userName,
      'email': email,
      if (fcmtoken != null) 'fcmtoken': fcmtoken,
      'tablecardfields': cardFields,
      'is_push_on': true,
      if (signupRef != null) 'signup_ref': signupRef,
    };
    final response = await http.put(
      url,
      headers: await firebaseAuthHeaders(forceRefresh: true),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to ensure User: ${response.statusCode} ${response.body}',
    );
  }
  
  Future<UserModel> changeRole({
    required String targetStaffId
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/change-role/$targetStaffId');
    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(forceRefresh: true),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to change role: ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> removeUserFromCompany({
    required String targetUserId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/remove/$targetUserId');

    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to remove user from company: ${response.body}');
    }
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteUser({required String userId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/$userId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception(
      'Failed to delete User: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> changeOwner({required String targetUserId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/change-owner/$targetUserId');

    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to change owner: ${response.body}');
    }
  }

  Future<UserModel> setUserAsCustomer() async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/set-customer');
    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to set user as customer: ${response.statusCode} ${response.body}',
    );
  }

  Future<UserModel> verifyPhoneNumber() async {
    final url = Uri.parse('${ApiClient.baseUrl}/verify-phonenumber');
    final response = await http.post(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    throw Exception(
      'Failed to verify phonenumber: ${response.statusCode} ${response.body}',
    );
  }
}
