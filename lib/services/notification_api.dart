import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/notification_model.dart';
import 'package:tablebid/services/api_client.dart';

class NotificationApi {
  Future<List<NotificationModel>> getNotifications(String companyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/$companyId/notifications');
    final response = await http.get(url);

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((elem) => NotificationModel.fromJson(elem)).toList();
    }
    throw Exception(
      'Failed to get notifications: ${response.statusCode} ${response.body}'
    );
  }

}