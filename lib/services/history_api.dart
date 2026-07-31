import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/table_history_model.dart';
import 'package:tablebid/services/api_client.dart';

class HistoryApi {
  Future<TableHistoryModel> getHistory(int historyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/histories/${historyId}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableHistoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to get History: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<TableHistoryModel>> getHistoriesByTable(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/${tableId}/histories');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TableHistoryModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Histories: ${response.statusCode} ${response.body}',
    );
  }

  Future<TableHistoryModel> tableOutAndCreateHistory({
    required String tableId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/out');

    final response = await http.post(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableHistoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to out Table and Create a History: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> reRegisterTable({
    required int historyId,
    required String tableId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/$tableId/re-register/histories/$historyId',
    );

    final response = await http.post(url);

    if (response.statusCode == 200) {
      return;
    }
    throw Exception(
      "Failed to reregister table: ${response.statusCode} ${response.body}",
    );
  }
}
