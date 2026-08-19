import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tablebid/models/set_menu_model.dart';
import 'package:tablebid/services/api_client.dart';

class SetMenuApi {
  Future<SetMenuModel> updateSetMenu(
    {
      required String companyId,
      required int setMenuId,
      bool? isActive,
      String? setName,
      int? setPrice,
      bool? hasMixer,
    }
  ) async {
    final url = Uri.parse('${ApiClient.baseUrl}/companies/${companyId}/set-menus/${setMenuId}');
    final body = {
      if (isActive != null) 'is_active': isActive,
      if (setName != null) 'set_name': setName,
      if (setPrice != null) 'set_price': setPrice,
      if (hasMixer != null) 'has_mixer': hasMixer,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body)
    );

    if(response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return SetMenuModel.fromJson(data);
    }
    throw Exception(
      'Failed to modify Set Menu: ${response.statusCode} ${response.body}'
    );
  }
}
