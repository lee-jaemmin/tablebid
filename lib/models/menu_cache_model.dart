import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/models/set_menu_items_model.dart';
import 'package:tablebid/models/set_menu_model.dart';

class MenuCacheModel {
    final String companyId;
    final List<CategoryModel> categories;
    final List<ItemModel> items;
    final List<SetMenuModel> setMenus;
    final List<SetMenuItemsModel> setMenuItems;
    

    MenuCacheModel({
      required this.companyId,
      required this.categories,
      required this.items,
      required this.setMenus,
      required this.setMenuItems,
    });

    factory MenuCacheModel.fromJson(Map<String, dynamic> json) {
      return MenuCacheModel(
        companyId: json['company_id'],
        categories: (json['categories'] as List<dynamic>)
            .map((e) => CategoryModel.fromJson(e))
            .toList(),
        items: (json['items'] as List<dynamic>)
            .map((e) => ItemModel.fromJson(e))
            .toList(),
        setMenus: (json['set_menus'] as List<dynamic>)
        .map((e)=>SetMenuModel.fromJson(e)).toList(),
        setMenuItems: (json['set_menu_items'] as List<dynamic>)
        .map((e)=>SetMenuItemsModel.fromJson(e)).toList(),
      );
    }
  }
