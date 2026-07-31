import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/item_model.dart';
import 'api_client.dart';

class ItemApi {
  Future<List<ItemModel>> getItems(String companyId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/${companyId}/items');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ItemModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Items: ${response.statusCode} ${response.body}',
    );
  }

  Future<ItemModel> createItem({
    required String itemName,
    required int itemPrice,
    required int categoryId,
    required String companyId,
    required bool isActive,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/items');

    final body = {
      'item_name': itemName,
      'item_price': itemPrice,
      'is_active': isActive,
      'company_id': companyId,
      'category_id': categoryId,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ItemModel.fromJson(data);
    }
    throw Exception(
      'Failed to create Item: ${response.statusCode} ${response.body}',
    );
  }

  Future<ItemModel> updateItem({
    required int itemId,
    String? itemName,
    int? itemPrice,
    bool? isActive,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/items/$itemId');

    final body = {
      if (itemName != null) 'item_name': itemName,
      if (itemPrice != null) 'item_price': itemPrice,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ItemModel.fromJson(data);
    }
    throw Exception(
      'Failed to modify Item: ${response.statusCode} ${response.body}',
    );
  }
}
