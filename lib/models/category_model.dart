class CategoryModel {
  final int id;
  final String categoryName;
  final int sortOrder;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.categoryName,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      categoryName: json['category_name'],
      sortOrder: json['sort_order'],
      isActive: json['is_active'],
    );
  }
}