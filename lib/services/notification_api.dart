import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/notification_model.dart';
import 'package:tablebid/services/api_client.dart';

class NotificationApi {
  Future<List<NotificationModel>> getNotifications({
    required String companyId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final end = endTime ?? DateTime.now();
    final start = startTime ?? end.subtract(const Duration(hours: 3));
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/$companyId/notifications',
    ).replace(queryParameters: {
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
    });
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((elem) => NotificationModel.fromJson(elem)).toList();
    }
    throw Exception(
      'Failed to get notifications: ${response.statusCode} ${response.body}',
    );
  }
}
