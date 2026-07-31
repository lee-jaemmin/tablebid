import 'package:tablebid/models/category_model.dart';
import 'package:tablebid/models/item_model.dart';

class MenuCacheModel {
    final String companyId;
    final List<CategoryModel> categories;
    final List<ItemModel> items;

    MenuCacheModel({
      required this.companyId,
      required this.categories,
      required this.items,
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
      );
    }
  }
