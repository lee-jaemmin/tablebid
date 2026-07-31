import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/log_model.dart';
import 'api_client.dart';

class LogApi {
  Future<List<LogModel>> getLogs(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/${tableId}/purchase-logs');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LogModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Logs: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> createLogAndPurchases({
    required String tableId,
    required int itemId,
    required int quantity,
    required String userId,
    required String batchId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/register-purchase');

    final body = {
      'table_id': tableId,
      'item_id': itemId,
      'quantity': quantity,
      'user_id': userId,
      'batch_id': batchId,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception(
      'Failed to create Log: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteLogs({
    required String tableId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/purchase-logs');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete Logs: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteLogAndPurchase({
    required int logId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/purchase-logs/$logId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete Log: ${response.statusCode} ${response.body}',
    );
  }
}
