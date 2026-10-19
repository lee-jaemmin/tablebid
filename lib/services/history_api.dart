import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/methods/firebase_auth.dart';
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

  Future<List<TableHistoryModel>> getHistoriesByTable({
    required String tableId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final end = endTime ?? DateTime.now();
    final start = startTime ?? end.subtract(const Duration(hours: 3));
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/${tableId}/histories',
    ).replace(queryParameters: {
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
    });
    // schema는 귀찮고 path parameter로 넣자니 인코딩이 불안해서 query parameter로 해결

    final response = await http.get(url, headers: await firebaseAuthHeaders());

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
