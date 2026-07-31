import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/table_history_model.dart';
import '../models/table_purchases_model.dart';
import 'api_client.dart';

class PurchaseApi {
  Future<List<TablePurchasesModel>> getPurchases(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/${tableId}/purchases');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TablePurchasesModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Purchases: ${response.statusCode} ${response.body}',
    );
  }

  Future<TablePurchasesModel> createPurchase({
    required String tableId,
    required int itemId,
    required int quantity,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/purchases');

    final body = {
      'table_id': tableId,
      'item_id': itemId,
      'quantity': quantity,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TablePurchasesModel.fromJson(data);
    }
    throw Exception(
      'Failed to create purchase: ${response.statusCode} ${response.body}',
    );
  }

  Future<TableHistoryModel> tableOut({
    required String tableId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/$tableId/out',
    );

    final response = await http.post(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableHistoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to table out: ${response.statusCode} ${response.body}'
    );
  }

  Future<TablePurchasesModel> updatePurchase({
    required int purchaseId,
    String? itemName,
    int? quantity,
    String? tableId,
    int? unitPrice,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/purchases/$purchaseId');

    final body = {
      if (itemName != null) 'item_name': itemName,
      if (quantity != null) 'quantity': quantity,
      if (tableId != null) 'table_id': tableId,
      if (unitPrice != null) 'unit_price': unitPrice,
    };

    final response = await http.patch(
      url,
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TablePurchasesModel.fromJson(data);
    }
    throw Exception(
      'Failed to update User : ${response.statusCode} ${response.body}',
    );
  }
  Future<void> deletePurchase({
    required int purchaseId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/purchases/$purchaseId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Failed to delete Purchase: ${response.statusCode} ${response.body}',
    );
  }
}
