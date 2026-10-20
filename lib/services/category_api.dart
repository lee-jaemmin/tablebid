import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/models/category_model.dart';
import 'api_client.dart';

class CategoryApi {
   Future<List<CategoryModel>> getCategoriesByCompany() async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories-by-company/');

    final response = await http.get(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json)=>CategoryModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get Category by company: ${response.statusCode} ${response.body}',
    );
  }

  Future<CategoryModel> createCategory({
    required String categoryName,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/categories');

    final body = {
      'category_name': categoryName,
      'sort_order': 0,
      'is_active': true,
    };

    final response = await http.post(
      url,
      headers: await firebaseAuthHeaders(),
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
    final url = Uri.parse('${ApiClient.baseUrl}/categories/$categoryId');

    final body = {
      if (categoryName != null) 'category_name': categoryName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
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
