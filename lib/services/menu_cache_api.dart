import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/menu_cache_model.dart';
import 'package:tablebid/services/api_client.dart';

class MenuCacheApi {
    Future<MenuCacheModel> getMenuCache(String companyId) async {
      final url = Uri.parse('${ApiClient.baseUrl}/companies/$companyId/menu-cache');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return MenuCacheModel.fromJson(jsonDecode(response.body));
      }
      throw Exception(
        'Failed to get menu cache: ${response.statusCode} ${response.body}',
      );
    }
  }