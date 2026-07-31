import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/category_model.dart';
import 'api_client.dart';

class CategoryApi {
  Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Categories: ${response.statusCode} ${response.body}',
    );
  }

  Future<CategoryModel> getCategory(int categoryId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories/$categoryId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CategoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to get Category: ${response.statusCode} ${response.body}',
    );
  }

  Future<CategoryModel> createCategory({
    required String categoryName,
    int? sortOrder,
    bool? isActive,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories');

    final body = {
      'category_name': categoryName,
      'sort_order': sortOrder,
      'is_active': isActive,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CategoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to create Category: ${response.statusCode} ${response.body}',
    );
  }

  Future<CategoryModel> updateCategory({
    required int categoryId,
    String? categoryName,
    int? sortOrder,
    bool? isActive,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories');

    final body = {
      if (categoryName != null) 'category_name': categoryName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CategoryModel.fromJson(data);
    }
    throw Exception(
      'Failed to update Category: ${response.statusCode} ${response.body}',
    );
  }
}
