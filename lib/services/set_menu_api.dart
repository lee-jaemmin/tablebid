import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tablebid/models/set_menu_model.dart';
import 'package:tablebid/screens/set_menu_create_screen.dart';
import 'package:tablebid/services/api_client.dart';

class SetMenuApi {
  Future<SetMenuModel> updateSetMenu({
    required String companyId,
    required int setMenuId,
    bool? isActive,
    String? setName,
    int? setPrice,
    bool? hasMixer,
    List<SelectedComponents>? components,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/companies/${companyId}/set-menus/${setMenuId}',
    );
    final body = {
      if (isActive != null) 'is_active': isActive,
      if (setName != null) 'set_name': setName,
      if (setPrice != null) 'set_price': setPrice,
      if (hasMixer != null) 'has_mixer': hasMixer,
      if (components != null) 'items': components.map((elem)=>{
        "item_id": elem.itemId,
        "quantity": elem.quantity,
      }).toList()
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return SetMenuModel.fromJson(data);
    }
    throw Exception(
      'Failed to modify Set Menu: ${response.statusCode} ${response.body}',
    );
  }

  Future<SetMenuModel> createSetMenu({
    required String companyId,
    required String setName,
    required int setPrice,
    required bool isActive,
    required bool hasMixer,
    required final List<SelectedComponents> components,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/set-menus');

    final body = {
      'company_id': companyId,
      'set_name': setName,
      'set_price': setPrice,
      'is_active': isActive,
      'has_mixer': hasMixer,
      'items': components
          .map(
            (component) => {
              "item_id": component.itemId,
              "quantity": component.quantity,
            },
          )
          .toList(), // toList: Iterable(map) => JSON 배열
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return SetMenuModel.fromJson(data);
    }
    throw Exception(
      'Failed to create set menu: ${response.statusCode} ${response.body}',
    );
  }

  Future<String> getSetMenuItemsBySetMenu({required int setMenuId}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/set-menus/$setMenuId/items');

    final response = await http.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as String;
      return data;
    }
    throw Exception(
      'Failed to get set menu items by set menu: ${response.statusCode} ${response.body}',
    );
  }
}
