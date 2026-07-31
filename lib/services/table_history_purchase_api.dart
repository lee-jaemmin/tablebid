import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tablebid/models/table_history_purchase_model.dart';
import 'package:tablebid/services/api_client.dart';

class TableHistoryPurchaseApi {
  Future<TableHistoryPurchaseModel> getHistoryPurchase(int hpId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/history-purchases/$hpId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableHistoryPurchaseModel.fromJson(data);
    }
    throw Exception(
      'Failed to get History: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<TableHistoryPurchaseModel>> getHpByTable(String tableId) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/$tableId/history-purchases',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => TableHistoryPurchaseModel.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get Histories by Table: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<TableHistoryPurchaseModel>> getHpByHistory(
    int historyId,
  ) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/histories/$historyId/history-purchases',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => TableHistoryPurchaseModel.fromJson(json))
          .toList();
    }
    throw Exception(
      'Failed to get Histories by Table: ${response.statusCode} ${response.body}',
    );
  }
}
