import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/models/log_model.dart';
import 'package:tablebid/screens/purchase_screen.dart';
import 'api_client.dart';

class LogApi {
  Future<List<LogModel>> getLogs(String tableId) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/${tableId}/purchase-logs',
    );

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
    required String batchId,
    required String userId,
    required List<SelectedItem> newPurchases,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/register-purchase');

    final body = {
      'table_id': tableId,
      'batch_id': batchId,
      'items': newPurchases.map((purchase) {
        return {
          if (purchase.productType == ProductType.item)
            'item_id': purchase.itemId
          else
            'set_menu_id': purchase.itemId,
          'quantity': purchase.quantity,
        };
      }).toList(),
    };

    final response = await http.post(
      url,
      headers: await firebaseAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception(
      'Failed to create Log: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteLogs({required String tableId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/purchase-logs');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete Logs: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteLogAndPurchase({required int logId}) async {
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
