import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/table_model.dart';
import 'api_client.dart';

class TableApi {
  Future<List<TableModel>> getTables(String companyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/${companyId}/tables');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TableModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get tables: ${response.statusCode} ${response.body}',
      // 404, '{"detail": "Table not found"}' (String임)
    );
  }

  Future<TableModel> getTable(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/${tableId}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TableModel.fromJson(data);
    }
    throw Exception(
      'Failed to get a table: ${response.statusCode} ${response.body}',
    );
  }

  Future<TableModel> updateTable({
    required String tableId,
    String? tableName,
    String? status,
    String? section,
    String? customer,
    String? tablename,
    String? phonenumber,
    int? persons,
    int? totalPrice,
    String? remark,
    String? userId,
    String? userName,
    bool? isReserved,
    DateTime? registeredAt,
    DateTime? timerStartedAt,
    DateTime? timerEndAt,
    DateTime? timerAlertSentAt,
    String? purchaseSummary,
    bool clearTimer = false,
    DateTime? reservedAt,
    DateTime? bidEndAt,
    bool? bidAvailable,
    int? leastBidPrice,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId');
    final currentTable = await getTable(tableId);
    String newName;

    if (userName == null || userName == "") {
      newName = "";
    } else {
      if (currentTable.userName == null || currentTable.userName == "") {
        newName = userName;
      } else {
        newName = '${currentTable.userName}\n${userName}';
      }
    }

    final body = {
      if (tableName != null) 'tablename': tableName,
      if (section != null) 'section': section,
      if (status != null) 'status': status,
      if (customer != null) 'customer': customer,
      if (totalPrice != null) 'total_price': totalPrice,
      if (phonenumber != null) 'phonenumber': phonenumber,
      if (persons != null) 'persons': persons,
      if (remark != null) 'remark': remark,
      if (isReserved != null) 'is_reserved': isReserved,
      if (userId != null) 'user_id': userId,
      'user_name': newName,
      if (registeredAt != null)
        'registered_at': registeredAt.toUtc().toIso8601String(),
      if (reservedAt != null)
        'reserved_at': reservedAt.toUtc().toIso8601String(),
      if (purchaseSummary != null) 'purchase_summary': purchaseSummary,
      if (clearTimer) ...{
        'timer_started_at': null,
        'timer_end_at': null,
        'timer_alert_sent_at': null,
      } else ...{
        if (timerStartedAt != null)
          'timer_started_at': timerStartedAt.toUtc().toIso8601String(),
        if (timerEndAt != null)
          'timer_end_at': timerEndAt.toUtc().toIso8601String(),
        if (timerAlertSentAt != null)
          'timer_alert_sent_at': timerAlertSentAt.toUtc().toIso8601String(),
      },
      if (bidEndAt != null) 'bid_end_at': bidEndAt.toUtc().toIso8601String(),
      if (bidAvailable != null) 'bid_available': bidAvailable,
      if (leastBidPrice != null) 'least_bid_price': leastBidPrice,
    };
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableModel.fromJson(data);
    }
    throw Exception(
      'Failed to modify a Table: ${response.statusCode} ${response.body}',
    );
  }

  Future<TableModel> createTable({
    required String companyId,
    required String section,
    required String tablename,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables');

    final body = {
      'company_id': companyId,
      'section': section,
      'tablename': tablename,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableModel.fromJson(data);
    }
    throw Exception(
      'Failed to create Table: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteTable({
    required String tableId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete Table: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> moveTable({
    required String fromTableId,
    required String toTableId,
  }) async {
    final url = Uri.parse("${ApiClient.baseUrl}/table-move").replace(
      queryParameters: {
        'from_table_id': fromTableId,
        'to_table_id': toTableId,
      },
    );

    final response = await http.post(url);

    print("✅response body: ${response.body}");
    if (response.statusCode == 200) {
      return;
    }
    throw Exception("Failed to move table");
  }
}
